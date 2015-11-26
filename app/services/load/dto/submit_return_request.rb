class SubmitReturnRequest < UpdateLoadRequest
  attr_accessor :order_ids

  def initialize (delivery_date, delivery_shift, order_ids, truck_id)
    super(delivery_date, delivery_shift, truck_id)
    @order_ids = order_ids
  end
end