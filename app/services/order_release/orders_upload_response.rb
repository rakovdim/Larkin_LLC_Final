class OrdersUploadResponse
  attr_accessor :result, :invalid_orders

  def initialize(result, invalid_orders={})
    @result = result
    @invalid_orders = invalid_orders
  end

  def self.success
    OrdersUploadResponse.new(true)
  end

  def self.fails (invalid_orders)
    OrdersUploadResponse.new(false, invalid_orders)
  end
end