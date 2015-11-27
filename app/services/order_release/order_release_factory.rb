class OrderReleaseFactory

  def create_order_release(params)
    delivery_date = params[:delivery_date]
    delivery_shift = params[:delivery_shift]
    mode = params[:mode]
    handling_unit_type = params[:handling_unit_type]

    order_release = OrderRelease.new(params.except(:delivery_date).
        except(:delivery_shift).
        except(:mode).
        except (:handling_unit_type))

    set_value_internal(order_release, :delivery_date, 'incorrect format, should be: mm/dd/YYYY', lambda { |order|
      order.delivery_date = get_delivery_date(delivery_date) })

    set_value_internal(order_release, :delivery_shift, 'incorrect format, should be empty or one of {M,N,E}', lambda { |order|
      order.delivery_shift = get_delivery_shift(delivery_shift) })

    set_value_internal(order_release, :mode, "incorrect format, should be 'TRUCKLOAD'", lambda { |order|
      order.mode = get_mode(mode) })

    set_value_internal(order_release, :handling_unit_type, "incorrect format, should be: 'box'", lambda { |order|
      order.handling_unit_type = get_unit_type(handling_unit_type) })
    order_release

  end

  private

  def set_value_internal (order, field_name, error_message, set_action)
    begin
      set_action.call(order)
    rescue ArgumentError => e
      order.add_custom_validation_error(field_name, error_message)
    end
  end


  def get_delivery_shift (str)
    return OrderRelease.delivery_shifts[:any_time] if str.nil? ||str.length == 0 || str=='any_time'
    return OrderRelease.delivery_shifts[:morning] if str == 'M' ||str=='m' || str=='morning'
    return OrderRelease.delivery_shifts[:afternoon] if str == 'N' ||str=='n' || str=='afternoon'
    return OrderRelease.delivery_shifts[:evening] if str == 'E' ||str=='e' || str=='evening'
    raise ArgumentError.new
  end

  def get_delivery_date (delivery_date_str)
    if delivery_date_str.nil? || delivery_date_str.length == 0
      nil
    else
      begin
        Date.strptime(delivery_date_str, "%m/%d/%Y")
      rescue ArgumentError => e
        raise ArgumentError.new
      end
    end
  end

  def get_unit_type (str)
    if str.nil? || str.length ==0
      return nil
    end
    case str
      when 'box' || 'BOX'
        OrderRelease.handling_unit_types[:box]
      else
        raise ArgumentError.new
    end
  end

  def get_mode (str)
    if str.nil? || str.length ==0
      return nil
    end
    case str
      when 'TRUCKLOAD' || 'truckload'
        OrderRelease.modes[:TRUCKLOAD]
      else
        raise ArgumentError.new
    end
  end
end
