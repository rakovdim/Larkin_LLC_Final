class LoadService
  def initialize
    @load_validator = LoadConstructionValidator.new
  end

  #todo fix kamaz. trucks should be loaded here
  def get_current_load
    ActiveRecord::Base.transaction do
      delivery_date = Date.today
      delivery_shift = Load.delivery_shifts[:morning]
      get_or_create_load(delivery_date, delivery_shift)
    end
  end

  def get_load_by_date_and_shift(delivery_date, delivery_shift)
    Load.where('delivery_date=? and delivery_shift=?', delivery_date, delivery_shift).first
  end

  def complete_load (delivery_date, delivery_shift)
    ActiveRecord::Base.transaction do
      load = get_load_by_date_and_shift(delivery_date, delivery_shift)
      puts load.id
      @load_validator.validate_load_not_planned(load)
      load.order_releases.each do |order_release|
        @load_validator.validate_order_not_planned(order_release)
        order_release.planned_for_delivery!
      end
      DeliveryEmulator.new(load).perform_dryrun_delivery
      load.planned_for_delivery!
      load.save!
      load
    end
  end

  def return_orders(return_request)
    load = nil
    ActiveRecord::Base.transaction do
      load = get_load_by_date_and_shift(return_request.delivery_date, return_request.delivery_shift)
      @load_validator.validate_load_not_planned(load)
      return_orders_ids = return_request.order_ids
      load.order_releases.each do |order_release|
        if return_orders_ids.include?(order_release.id)
          order_release.stop_order_number=nil
          load.order_releases.delete(order_release)
          order_release.save!
        end
      end
      apply_ordering(load)
      load.save!
    end
    load
  end

  #todo validate if truck exists
  #todo check is order already in load
  #todo I have no guaranty that orders are loaded in order according to ids order
  def submit_orders (submit_request)
    load = nil
    ActiveRecord::Base.transaction do
      load = get_or_create_load(submit_request.delivery_date, submit_request.delivery_shift)
      @load_validator.validate_load_not_planned(load)
      update_truck_for_load(load, submit_request.truck_id)
      new_orders = OrderRelease.find (submit_request.order_ids)
      add_orders_to_load(load, new_orders)
      apply_ordering(load)
      #DeliveryEmulator.new(load).perform_dryrun_delivery
      load.save!
    end
    raise InternalLoadConstructingException.new('Load constructing operation failed. Load is nil') if load==nil
    load
  end

  def reorder_planning_orders (reordering_request)
    old_pos = reordering_request.old_position
    new_pos = reordering_request.new_position
    load = nil
    ActiveRecord::Base.transaction do
      load = Load.find_by_order_id(reordering_request.order_id)
      raise InternalLoadConstructingException.new ('load is nil for order: '+reordering_request.order_id) if load==nil
      @load_validator.validate_load_not_planned(load)
      move_order_to_new_position(load, old_pos, new_pos)
     # DeliveryEmulator.new(load).perform_dryrun_delivery
      load.save!
    end
    load
  end

  private

  #todo validation if load.hasOrders
  def move_order_to_new_position(load, old_pos, new_pos)

    orders = []
    orders.concat(load.order_releases)
    orders.insert(new_pos, orders.delete_at(old_pos))
    orders_map = get_orders_map(load)
    orders.each_with_index do |order_release, index|
      orders_map[order_release.id].stop_order_number = index
    end
    orders
  end

  def add_orders_to_load(load, new_orders)
    new_orders.each do |order|
      @load_validator.validate_order(order, load)
      load.order_releases << order
    end
  end

  def update_truck_for_load(load, truck_id)
    puts load.truck

    if load.truck.nil? || load.truck.id != truck_id
      load.truck = Truck.find(truck_id)
    end
  end

  #todo may be do it in the first cycle
  #todo get last order_number and continue
  def apply_ordering (load)
    order = 0
    load.order_releases.each do |order_release|
      order_release.stop_order_number = order
      order = order+1
    end
  end

  def get_or_create_load(delivery_date, delivery_shift)
    load = get_load_by_date_and_shift delivery_date, delivery_shift
    load = Load.new(:delivery_shift => delivery_shift,
                    :delivery_date => delivery_date) unless load
    load
  end

  def get_orders_map(load)
    result = {}
    load.order_releases.each do |order|
      result[order.id]=order
    end
    puts result
    result
  end

end