class OrdersCollectingResponse
  def initialize (data, recordsTotal, load_status, truck_volume, truck_id, load_id)
    @data = data
    @recordsTotal = recordsTotal
    @recordsFiltered = recordsTotal
    @load_status = load_status
    @truck_volume = truck_volume
    @truck_id = truck_id
    @load_id = load_id
  end

  def set_draw(draw)
    @draw =draw
  end

  def set_errors(errors)
    @errors =errors
  end

  def self.create_av_orders_response(data, recordsTotal)
    OrdersCollectingResponse.new(data, recordsTotal, nil, nil, nil, nil)
  end

  def self.create_plan_orders_response (data, recordsTotal, load_status, truck_volume, truck_id, load_id)
    OrdersCollectingResponse.new(data, recordsTotal, load_status, truck_volume, truck_id, load_id)
  end

end