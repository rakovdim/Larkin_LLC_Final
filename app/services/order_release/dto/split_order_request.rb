class SplitOrderRequest
  attr_accessor :order_id, :new_quantity, :new_volume

  def initialize (order_id, new_quantity, new_volume)
    @order_id = order_id
    @new_quantity = new_quantity
    @new_volume = new_volume
  end
end