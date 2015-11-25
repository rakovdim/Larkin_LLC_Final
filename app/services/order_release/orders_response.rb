class OrdersResponse
  def initialize (data, recordsTotal, load_status, truck_volume)
    @data = data
    @recordsTotal = recordsTotal
    @recordsFiltered = recordsTotal
    @load_status = load_status
    @truck_volume = truck_volume
  end

  def set_draw(draw)
    @draw =draw
  end

  def set_errors(errors)
    @errors =errors
  end

end