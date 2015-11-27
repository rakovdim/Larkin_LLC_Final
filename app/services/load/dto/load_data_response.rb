class LoadDataResponse < OrdersCollectingResponse
  def initialize(order_releases, orders_count, load_status, truck_volume, truck_id, load_id)
    super(order_releases, orders_count)
    @load_status = load_status
    @truck_volume = truck_volume
    @truck_id = truck_id
    @load_id = load_id
  end

  def self.create (load)
    if load
      LoadDataResponse.new(load.order_releases,
                           load.order_releases.length,
                           load.status.humanize,
                           load.total_volume,
                           load.truck_id,
                           load.id,
      )
    else
      LoadDataResponse.new([], 0,
                           OrderRelease.not_planned_status.humanize,
                           0, nil, nil)
    end
  end
end