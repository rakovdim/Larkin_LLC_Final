class SubmitReturnRequest
  attr_accessor :delivery_date, :delivery_shift, :order_ids, :truck_id

  #todo move to contoller logic
  def initialize (delivery_date, delivery_shift, order_ids, truck_id)
    @delivery_date = delivery_date
    @delivery_shift = delivery_shift
    @order_ids = []
    order_ids.each do |order_id|
      @order_ids<<order_id.to_i
    end
    @truck_id = truck_id
  end
end