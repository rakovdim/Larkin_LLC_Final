class OrdersRequest
  attr_accessor :required_columns, :start, :length, :delivery_date, :delivery_shift

  def initialize(required_columns, start, length, delivery_date, delivery_shift)
    @required_columns = required_columns
    @start = start.to_i
    @length = length.to_i
    @delivery_date = delivery_date
    @delivery_shift = delivery_shift
  end
end