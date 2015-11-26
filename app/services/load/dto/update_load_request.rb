class UpdateLoadRequest < DateShiftRequest
  attr_accessor :truck_id

  def initialize (date, shift, truck_id)
    super(date, shift)
    @truck_id = truck_id
  end
end