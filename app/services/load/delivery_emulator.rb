class DeliveryEmulator
  def initialize(load)
    @load=load
    @truck_capacity = load.truck.max_capacity
    @in_truck_orders_volume = 0
  end

  def perform_dryrun_delivery
    #todo can be simplified by calling load.get_delivery_volume
    perform_dryrun_orders_loading

    perform_dryrun_orders_delivery
  end

  private
  def perform_dryrun_orders_loading
    @load.order_releases.each do |order|
      @in_truck_orders_volume = @in_truck_orders_volume+order.volume if order.delivery?
      validate_truck_overload(order)
    end
  end

  def perform_dryrun_orders_delivery
    @load.order_releases.each do |order|
      puts "try to deliver order: #{order.purchase_order_number}, truck volume: #{@in_truck_orders_volume}"
      perform_delivery_step(order)
      #validate_truck_overload(order)
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
      raise DeliveryFailException.new ('Not enough capacity in load because of order: '+order.purchase_order_number)
    end
  end
end