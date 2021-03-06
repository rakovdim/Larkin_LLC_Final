class LoadService
  def initialize
    @model_validator = ModelValidator.new
  end

  # Returns load with orders which is assigned on corresponding driver
  # In case is there are no load, stub is returned
  def get_load_for_driver(date_shift_request, driver_id)
    TxUtils.execute_transacted_action(lambda {
      load = get_or_create_load_by_driver(date_shift_request.delivery_date, date_shift_request.delivery_shift, driver_id)
      LoadDataResponse.new(load)
    })
  end

  # Method is used to construct data for initial load planning
  # It requires:
  #   1) Load data for today if exists (if not, then stub is returned)
  #   2) Trucks list which are available for loading
  # Method returns load for today and morning shift
  # If load doesn't exist then stub object is returned
  #
  # Note! To simplify UI visualization process 2014 year is set as current year
  def get_initial_load_data
    TxUtils.execute_transacted_action(lambda {
      delivery_date = Date.today - 1.year
      delivery_shift = Load.delivery_shifts[:morning]
      load = get_or_create_load(delivery_date, delivery_shift)
      all_trucks = Truck.all
      puts all_trucks
      CurrentLoadResponse.new(load, all_trucks)
    })
  end

  # Returns data of requested order
  # Returns stub values if load does not exist
  def get_load_data (date_shift_request)
    TxUtils.execute_transacted_action(lambda {
      load = get_or_create_load date_shift_request.delivery_date,
                                date_shift_request.delivery_shift

      LoadDataResponse.new(load)
    })
  end

  # Updates truck for load if load is not planned for delivery
  def update_load_data(update_request)
    TxUtils.execute_transacted_action (lambda {
      load = get_load_by_date_and_shift(update_request.delivery_date, update_request.delivery_shift)
      return if load == nil
      @model_validator.validate_object_not_planned(load)
      perform_load_data_update(load, update_request)
      load.save!
    })
  end

  # Reopens requested load switching it and its orders in Not Planning state
  # Operation is applicable only for Planned for Delivery loads
  def reopen_load (date_shift_request)
    TxUtils.execute_transacted_action (lambda {
      load = get_load_by_date_and_shift(date_shift_request.delivery_date, date_shift_request.delivery_shift)
      @model_validator.validate_object_planned(load)
      perform_load_status_change(load, OrderRelease.not_planned_status)
      load.save!
    })
  end

  # Completes requested load switching it and its orders in Planned for Delivery state
  # Operation is applicable only for Not Planned loads
  # In the end of transition performs delivery emulation
  # If emulation is unsuccessful then Exception is raised
  # Note that exception does rollback current tx
  def complete_load (date_shift_request)
    TxUtils.execute_transacted_action (lambda {
      load = get_load_by_date_and_shift(date_shift_request.delivery_date, date_shift_request.delivery_shift)
      @model_validator.validate_object_not_planned(load)
      perform_load_status_change(load, OrderRelease.planned_status)
      DeliveryEmulator.new(load).perform_dryrun_delivery
      load.save!
    })
  end

  # Deletes requested orders from load and make them available for further planning
  # If load is not in Not_Planning state, then exception is raised
  def return_orders(return_request)
    perform_submit_return_orders(return_request, lambda { |load, order_ids|
      delete_orders_from_load(load, order_ids) })
  end

  # Submits requested orders to load
  # Following validation steps are performed before addition:
  #  1) Ensure that load has not been planned already
  #  2) Ensure that load delivery date and shift correspond to load date and shift
  #  3) Ensure that order has not been added to any load already
  # If validations pass then requested orders are added to load 
  # Finally delivery emulation is performed. If emulation is unsuccessful then warning is raised
  # Note that warning doesn't rollback current transaction
  def submit_orders (submit_request)
    load = perform_submit_return_orders(submit_request, lambda { |load, order_ids|
      new_orders = OrderRelease.find (order_ids)
      add_orders_to_load(load, new_orders)
    })
    emulate_delivery_with_warning(load)
  end

  # Changes position of requested order in load according to old_position and new_position
  # If no load can't be found for this order then internal exception is raised
  # Validates that load has not been already planned
  # Finally method changes position of order and performs delivery emulation of entire load
  # If emulation is unsuccessful then warning is raised (doesn't rollback tx)
  def reorder_planning_orders (reordering_request)
    load = TxUtils.execute_transacted_action(lambda {
      old_pos = reordering_request.old_position
      new_pos = reordering_request.new_position
      load = Load.find_by_order_id(reordering_request.order_id)
      raise InternalModelOperationException.new ('load is nil for order: '+reordering_request.order_id) if load==nil
      @model_validator.validate_object_not_planned(load)
      move_order_to_new_position(load, old_pos, new_pos)
      load.save!
      load })
    emulate_delivery_with_warning(load)
  end

  private

  def perform_load_status_change(load, status)
    load.order_releases.each do |order_release|
      order_release.status = status
    end
    load.status = status
  end

  def perform_submit_return_orders(request, submit_return_action)
    TxUtils.execute_transacted_action(lambda {
      load = get_or_create_load(request.delivery_date, request.delivery_shift)
      @model_validator.validate_object_not_planned(load)
      perform_load_data_update(load, request)
      submit_return_action.call(load, request.order_ids)
      apply_ordering(load)
      load.save!
      load
    })
  end

  def perform_load_data_update (load, update_request)
    if load.truck==nil || load.truck.id != update_request.truck_id
      load.truck = Truck.find(update_request.truck_id)
    end
  end

  # It is not well constructed method
  # But i couldn't find any solution to reorder collection of children (order_release objects) inside Load
  # That's why i
  def move_order_to_new_position(load, old_pos, new_pos)
    orders = []
    orders.concat(load.order_releases)
    orders.insert(new_pos, orders.delete_at(old_pos))
    orders_map = get_orders_as_map(load)
    orders.each_with_index do |order_release, index|
      orders_map[order_release.id].stop_order_number = index+1
    end
    orders
  end

  def add_orders_to_load(load, new_orders)
    new_orders.each do |order|
      @model_validator.validate_order_for_load(order, load)
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

  def get_orders_as_map(load)
    result = {}
    load.order_releases.each do |order|
      result[order.id]=order
    end
    puts result
    result
  end

  def apply_ordering (load)
    order = 1
    load.order_releases.each do |order_release|
      order_release.stop_order_number = order
      order = order+1
    end
  end

  def emulate_delivery_with_warning (load)
    begin
      DeliveryEmulator.new(load).perform_dryrun_delivery
    rescue DeliveryEmulationException => e
      raise WarningException.new (e.message)
    end
  end

  def get_or_create_load_by_driver(delivery_date, delivery_shift, driver_id)
    load = Load.where(:delivery_date => delivery_date, :delivery_shift => delivery_shift).
        where.not(:status => Load.statuses[:not_planned]).
        joins(:truck).where(:trucks => {:driver_id => driver_id}).first

    unless load
      load = create_load(delivery_date, delivery_shift)
      load.truck = Truck.find_by_driver_id(driver_id)
    end

    load

  end

  def get_or_create_load(delivery_date, delivery_shift)
    load = get_load_by_date_and_shift(delivery_date, delivery_shift)

    load = create_load(delivery_date, delivery_shift) unless load

    load
  end


  def get_load_by_date_and_shift(delivery_date, delivery_shift)
    Load.where(:delivery_date => delivery_date, :delivery_shift => delivery_shift).first
  end

  def create_load(delivery_date, delivery_shift)
    Load.new(:delivery_shift => delivery_shift,
             :delivery_date => delivery_date,
             :order_releases => [])
  end

end