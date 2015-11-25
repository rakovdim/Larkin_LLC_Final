class OrderReorderingRequest
  attr_accessor :order_id, :old_position, :new_position

  def initialize(order_id, old_position, new_position)
    @order_id = order_id
    @old_position = old_position
    @new_position = new_position
  end
end