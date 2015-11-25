class LoadConstructionValidator

  def validate_load_not_planned(load)
    raise LoadConstructingException.new(incorrect_load_status_msg(load)) unless load.not_planned?
  end

  def validate_load_already_planned_(load)
    raise LoadConstructingException.new(incorrect_load_status_msg(load)) unless load.not_planned?
  end

  def validate_order (order, load)
    validate_order_not_planned (order)

    if !(order.any_time?) && !(order.delivery_shift == load.delivery_shift)
      raise LoadConstructingException.new(incorrect_delivery_shift_msg(load, order))
    end

    raise LoadConstructingException.new(incorrect_delivery_date_msg(load, order)) if order.delivery_date > load.delivery_date
  end

  def validate_order_not_planned (order)
    raise LoadConstructingException.new(incorrect_order_status_msg(order)) unless order.not_planned?
  end

  def truck_is_overloaded_error_msg (truck, load)
    'Truck is overloaded. Truck capacity: '+truck.capacity.to_s+', current volume: '+load.total_volume.to_s
  end

  def incorrect_load_status_msg(load)
    'Cant perform operation. Incorrect load status: '+load.status
  end

  def incorrect_order_status_msg(order)
    'Cant submit orders because order is not in not_planned status. Its status: '+order.status
  end

  def incorrect_delivery_shift_msg (load, order)
    'Incorrect delivery shift of order: '+order.purchase_order_number+'. Load is planning for: '+load.delivery_shift.to_s+', order shift: '+order.delivery_shift.to_s
  end

  def incorrect_delivery_date_msg (load, order)
    'Incorrect delivery date of order: '+order.purchase_order_number+'. Load is planning on: '+load.delivery_date.to_s+', order date: '+order.delivery_date.to_s
  end

end