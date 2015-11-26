class OrdersCollectingRequest < DateShiftRequest
  attr_accessor :required_columns, :start, :length

  def initialize(required_columns, start, length, delivery_date, delivery_shift)
    super(delivery_date, delivery_shift)
    @required_columns = required_columns
    @start = start.to_i
    @length = length.to_i
  end
end