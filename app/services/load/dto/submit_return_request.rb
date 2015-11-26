class SubmitReturnRequest < DateShiftRequest
  attr_accessor :order_ids, :truck_id

  def initialize (delivery_date, delivery_shift, order_ids, truck_id)
    super(delivery_date, delivery_shift)
    @order_ids = order_ids
    @truck_id = truck_id
  end
end