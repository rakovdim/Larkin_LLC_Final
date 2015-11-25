class OrderErrors
  attr_accessor :order_number, :error_messages

  def initialize(order_number, error_messages)
    @order_number=order_number
    @error_messages=error_messages
  end
end