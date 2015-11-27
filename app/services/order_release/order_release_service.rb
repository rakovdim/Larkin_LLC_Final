require 'activerecord-import'
ActiveRecord::Import.require_adapter('postgresql')

class OrderReleaseService

  def initialize
    @model_validator = ModelValidator.new
  end

  # Splits order on two parts based on new_volume and new_quantity params
  # Note! new_volume and new_quantity values are applied to existing order
  # It means that remaining volume and quantity are stored in new created order release
  # This new created order release is stored as available for planning order
  #
  # To split order next validation should be passed:
  #   1) Order should be in Not Planned state
  #   2) Order handling_unit_quantity should be greater than 1
  #   3) new_volume < order.volume and new_volume > 0
  #   4) new_quantity < order.quantity and new_quantity > 0
  def split_order(split_order_request)
    TxUtils.execute_transacted_action(lambda {
      order_release = OrderRelease.find(split_order_request.order_id)

      new_volume = split_order_request.new_volume
      new_quantity = split_order_request.new_quantity

      @model_validator.validate_order_for_splitting(order_release, new_volume, new_quantity)

      remaining_order_release = perform_splitting(order_release, new_volume, new_quantity)

      order_release.save!
      remaining_order_release.save!
    })
  end

  # Returns collection of orders which can be planned for delivery
  # It means that all returned orders meet following requirements:
  #   1) Order is in Not Planned status
  #   2) Order delivery shift is any_time or is equal to load delivery shift
  #   3) Order delivery date is less or equal to load delivery date
  #   4) Load_id of order is null (order doesn't belong to any load)
  # This method supports pagination to reduce returned data
  def get_available_orders (orders_request)
    TxUtils.execute_transacted_action(lambda {
      where_query_for_orders = where_query_for_orders(orders_request.delivery_date, orders_request.delivery_shift)
      found_orders = where_query_for_orders.select(orders_request.required_columns).offset(orders_request.start).limit(orders_request.length)
      total_count = where_query_for_orders.count
      puts found_orders.length
      OrdersCollectingResponse.new(found_orders, total_count)
    })
  end

  # Saves collection of orders bulk. Based on incoming orders params
  # All valid orders are stored in one SQL Batch to DB
  # All invalid orders are returned for further fixes
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
      OrderRelease.import valid_orders, :validate => false
    end
  end

  def where_query_for_orders (delivery_date, delivery_shift)
    OrderRelease.where('delivery_shift IN (?) and delivery_date <= ? and status=? and load_id is null',
                       [delivery_shift, OrderRelease.delivery_shifts[:any_time]], delivery_date, OrderRelease.statuses[:not_planned]).
        order(:delivery_shift)
  end

  def perform_splitting(order_release, new_volume, new_quantity)
    remaining_order_release = order_release.dup
    order_release.volume = new_volume
    order_release.handling_unit_quantity = new_quantity
    remaining_order_release.volume = remaining_order_release.volume-new_volume
    remaining_order_release.handling_unit_quantity = remaining_order_release.handling_unit_quantity-new_quantity
    remaining_order_release.load_id = nil
    remaining_order_release.stop_order_number = nil
    remaining_order_release
  end
end