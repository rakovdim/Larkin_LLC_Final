class OrdersCollectingRequest < DateShiftRequest
  attr_accessor :required_columns, :start, :length, :returns_only

  def initialize(required_columns, start, length, delivery_date, delivery_shift, returns_only)
    super(delivery_date, delivery_shift)
    @required_columns = required_columns
    @start = start
    @length = length
    @returns_only = returns_only
  end
end