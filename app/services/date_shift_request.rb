class DateShiftRequest
  attr_accessor :delivery_date, :delivery_shift

  def initialize (delivery_date, delivery_shift)
    @delivery_date = delivery_date
    @delivery_shift = delivery_shift
  end
end