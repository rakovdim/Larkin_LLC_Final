class ModelValidator

  #todo support set of statuses and don't refer to OrderRelease methods
  def validate_object_status (object, status)
    raise ModelOperationException.new(incorrect_object_status_msg(object, status)) if object.status != status
  end

  def validate_object_not_planned(object)
    validate_object_status(object, OrderRelease.not_planned_status)
  end

  def validate_object_planned(object)
    validate_object_status(object, OrderRelease.planned_status)
  end

  def validate_order_for_load (order, load)
    validate_object_not_planned (order)

    raise ModelOperationException(order_already_in_load_msg(order)) if order.load_id != nil

    if !order.any_time? && order.delivery_shift != load.delivery_shift
      raise ModelOperationException.new(incorrect_order_delivery_shift_msg(load, order))
    end

    raise ModelOperationException.new(incorrect_order_delivery_date_msg(load, order)) if order.delivery_date > load.delivery_date
  end

  def validate_order_for_splitting(order, new_volume, new_quantity)
    validate_object_not_planned(order)
    raise ModelOperationException(impossible_split_order_msg(order, "quantity can't be 1")) if order.handling_unit_quantity == 1
    raise ModelOperationException(impossible_split_order_msg(order, 'new volume should be positive')) if new_volume<=0
    raise ModelOperationException(impossible_split_order_msg(order, 'new quantity should be positive')) if new_quantity<=0
    raise ModelOperationException(impossible_split_order_msg(order, 'new volume should be less than original')) if new_volume>=order.volume
    raise ModelOperationException(impossible_split_order_msg(order, 'new quantity should be less than original')) if new_quantity>=order.handling_unit_quantity
  end

  private

  def incorrect_object_status_msg(object, status)
    "Cant perform operation. Incorrect object status: #{object.status}"
  end

  def incorrect_order_delivery_shift_msg(load, order)
    'Incorrect delivery shift of order: '+order.purchase_order_number+'. Load is planning for: '+load.delivery_shift.to_s+', order shift: '+order.delivery_shift.to_s
  end

  def incorrect_order_delivery_date_msg(load, order)
    'Incorrect delivery date of order: '+order.purchase_order_number+'. Load is planning on: '+load.delivery_date.to_s+', order date: '+order.delivery_date.to_s
  end

  def impossible_split_order_msg (order, reason)
    "Can't split order: #{order.purchase_order_number}, reason: #{reason}"
  end

  def order_already_in_load_msg (order)
    "Can't add order: #{order.purchase_order_number}, to load. It is already in some load"
  end

end