class OrderReleaseService

  def split_order(split_order_request)
    ActiveRecord::Base.transaction do
      order_release = OrderRelease.find(split_order_request.order_id)

      LoadConstructionValidator.new.validate_order_not_planned(order_release)
      raise SplitOrderException.new ("Can't split order #{order_release.purchase_order_number}. Not enough quantity") if order_release.handling_unit_quantity <= split_order_request.new_quantity
      raise SplitOrderException.new ("Can't split order #{order_release.purchase_order_number}. Not enough volume") if order_release.volume <= split_order_request.new_volume

      remaining_order_release = perform_splitting(order_release, split_order_request.new_quantity, split_order_request.new_volume)

      order_release.save!
      remaining_order_release.save!
    end
  end

  def collect_planning_orders (orders_request)
    ActiveRecord::Base.transaction do
      planning_orders = []
      load_status = OrderRelease.not_planned_status.humanize
      truck_volume = 0
      load = LoadService.new.get_load_by_date_and_shift orders_request.delivery_date,
                                                        orders_request.delivery_shift
      if load
        planning_orders = load.order_releases
        load_status = load.status.humanize
        truck_volume = load.delivering_total_volume
      end

      OrdersCollectingResponse.new planning_orders, planning_orders.length, load_status, truck_volume
    end
  end

  #todo refactor
  def collect_available_orders (orders_request)

    ActiveRecord::Base.transaction do
      where_query_for_orders = get_where_for_orders(orders_request.delivery_date, orders_request.delivery_shift)
      found_orders = where_query_for_orders.select(orders_request.required_columns).offset(orders_request.start).limit(orders_request.length)
      total_count = where_query_for_orders.count
      puts found_orders.length
      OrdersCollectingResponse.new found_orders, total_count, nil, nil
    end
  end

  def save_orders_bulk (orders_params_array)
    valid_orders = []
    invalid_orders = []
    orders_params_array.each do |params|
      order_release = OrderRelease.new params
      if order_release.valid?
        valid_orders << order_release
      else
        invalid_orders << order_release
      end
    end
    process_valid_invalid_orders valid_orders, invalid_orders
  end

  private

  def process_valid_invalid_orders (valid_orders, invalid_orders)

    process_valid_orders valid_orders

    if invalid_orders.empty?
      OrdersUploadResponse.success
    else
      OrdersUploadResponse.fails invalid_orders
    end
  end

  def process_valid_orders (valid_orders)
    OrderRelease.transaction do
      valid_orders.each do |order_release|
        order_release.save
      end
    end
  end

  def get_where_for_orders (delivery_date, delivery_shift)
    OrderRelease.where('delivery_shift IN (?) and delivery_date <= ? and status=? and load_id is null',
                       [delivery_shift, OrderRelease.delivery_shifts[:any_time]], delivery_date, OrderRelease.statuses[:not_planned]).
        order(:delivery_shift)
  end

  def perform_splitting(order_release, new_volume, new_quantity)
    remaining_order_release = order_release.clone
    order_release.volume = new_volume
    order_release.handling_unit_quantity = new_quantity
    remaining_order_release.volume = remaining_order_release.volume-new_volume
    remaining_order_release.handling_unit_quantity = remaining_order_release.handling_unit_quantity-new_quantity
    remaining_order_release.load_id = nil
    remaining_order_release
  end
end