class LoadDataResponse < OrdersCollectingResponse
  attr_accessor :load

  def initialize(load)
    super(load.order_releases, load.order_releases.length)
    @load = load
  end

  def as_json(options = {})
    result = super(options)
    result[:load_status] = load.status.humanize
    result[:truck_volume] = load.total_volume
    result[:truck_id] = load.truck_id
    result[:load_id] = load.id
    result.except('load')
  end

end