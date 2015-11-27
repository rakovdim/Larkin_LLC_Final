class DeliveryEmulator
  def initialize(load)
    @load=load
    @truck_capacity = load.truck.max_capacity
    @in_truck_orders_volume = 0
    #todo step can be optimized because sorting is need only in case of reordering now
    @sorted_by_stops_orders = sort_orders_by_stop_number(load)
  end

  def perform_dryrun_delivery
    #todo can be simplified by calling load.get_delivery_volume
    perform_dryrun_orders_loading

    perform_dryrun_orders_delivery
  end

  private
  def perform_dryrun_orders_loading
    @sorted_by_stops_orders.each do |order|
      @in_truck_orders_volume = @in_truck_orders_volume+order.volume if order.delivery?
      validate_truck_overload(order)
    end
  end

  def perform_dryrun_orders_delivery
    @sorted_by_stops_orders.each do |order|
      puts "try to deliver order: #{order.purchase_order_number}, truck volume: #{@in_truck_orders_volume}, stop order number: #{order.stop_order_number}"
      perform_delivery_step(order)
    end
  end

  def perform_delivery_step(order)
    if order.delivery?
      @in_truck_orders_volume = @in_truck_orders_volume - order.volume
    else
      @in_truck_orders_volume = @in_truck_orders_volume + order.volume
    end
    validate_truck_overload (order)
  end

  def validate_truck_overload(order)
    if @in_truck_orders_volume > @truck_capacity
      raise DeliveryEmulationException.new ('Not enough capacity in load because of order: '+order.purchase_order_number)
    end
  end

  def sort_orders_by_stop_number(load)
    sorted_by_stops_orders = []
    sorted_by_stops_orders.concat(load.order_releases)
    sorted_by_stops_orders.sort { |a, b| a.stop_order_number <=> b.stop_order_number }
  end
end