class OrdersCollectingResponse
  def initialize (data, recordsTotal)
    @data = data
    @recordsTotal = recordsTotal
    @recordsFiltered = recordsTotal
  end

  def set_draw(draw)
    @draw =draw
  end

  def set_errors(errors)
    @errors =errors
  end

end