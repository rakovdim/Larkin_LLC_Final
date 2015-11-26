class LoadService
  def initialize
    @load_validator = LoadConstructionValidator.new
  end

  def update_load_data(update_request)
    execute_transacted_action (lambda {
      load = get_load_by_date_and_shift(update_request.delivery_date, update_request.delivery_shift)
      return if load == nil
      @load_validator.validate_load_not_planned(load)
      process_update_load_request(load, update_request)
      load.save!
    })
  end

  #todo fix kamaz. trucks should be loaded here
  def get_current_load
    execute_transacted_action(lambda {
      delivery_date = Date.today - 1.year
      delivery_shift = Load.delivery_shifts[:morning]
      load = get_or_create_load(delivery_date, delivery_shift)
      all_trucks = Truck.all
      puts all_trucks
      CurrentLoadResponse.new(load, all_trucks)
    })
  end

  def get_load_by_date_and_shift(delivery_date, delivery_shift)
    Load.where('delivery_date=? and delivery_shift=?', delivery_date, delivery_shift).first
  end

  def reopen_load (date_shift_request)

  end

  def complete_load (date_shift_request)
    execute_transacted_action (lambda {
      load = get_load_by_date_and_shift(date_shift_request.delivery_date, date_shift_request.delivery_shift)
      puts load.id
      @load_validator.validate_load_not_planned(load)
      load.order_releases.each do |order_release|
        @load_validator.validate_order_not_planned(order_release)
        order_release.planned_for_delivery!
      end
      DeliveryEmulator.new(load).perform_dryrun_delivery
      load.planned_for_delivery!
      load.save! })
  end

  def return_orders(return_request)
    perform_submit_return_orders(return_request, lambda { |load, order_ids|
      delete_orders_from_load(load, order_ids) })
  end

  #todo I have no guaranty that orders are loaded in order according to ids order
  def submit_orders (submit_request)
    perform_submit_return_orders(submit_request, lambda { |load, order_ids|
      new_orders = OrderRelease.find (order_ids)
      add_orders_to_load(load, new_orders)
    })
  end

  def perform_submit_return_orders(request, submit_return_action)
    execute_transacted_action(lambda {
      load = get_or_create_load(request.delivery_date, request.delivery_shift)
      @load_validator.validate_load_not_planned(load)
      process_update_load_request(load, request)
      submit_return_action.call(load, request.order_ids)
      apply_ordering(load)
      #DeliveryEmulator.new(load).perform_dryrun_delivery
      load.save!
    })
  end

  def reorder_planning_orders (reordering_request)
    execute_transacted_action(lambda {
      old_pos = reordering_request.old_position
      new_pos = reordering_request.new_position
      load = Load.find_by_order_id(reordering_request.order_id)
      raise InternalLoadConstructingException.new ('load is nil for order: '+reordering_request.order_id) if load==nil
      @load_validator.validate_load_not_planned(load)
      move_order_to_new_position(load, old_pos, new_pos)
      # DeliveryEmulator.new(load).perform_dryrun_delivery
      load.save! })
  end

  private

  def process_update_load_request (load, update_request)
    if load.truck==nil || load.truck.id != update_request.truck_id
      load.truck = Truck.find(update_request.truck_id)
    end
  end

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

  def delete_orders_from_load(load, return_order_ids)
    load.order_releases.each do |order_release|
      if return_order_ids.include?(order_release.id)
        order_release.stop_order_number=nil
        load.order_releases.delete(order_release)
        order_release.save!
      end
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

  def execute_transacted_action (callback)
    ActiveRecord::Base.transaction do
      callback.call
    end
  end

end