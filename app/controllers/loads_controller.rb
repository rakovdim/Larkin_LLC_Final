class LoadsController < ApplicationController
  def index
    authorize_operation! :index
    @load = LoadService.new.get_current_load
    puts @load.delivering_total_volume
    @trucks = Truck.all
  end

  def split_order
    process_update_load_request(split_order_request, lambda { |request|
      OrderReleaseService.new.split_order(request)
    })
  end

  #todo how warning
  def return_orders
    process_update_load_request(submit_return_orders_request, lambda { |return_request|
      LoadService.new.return_orders(return_request)
    })
  end

  def reorder_planning_orders
    process_update_load_request(reorder_request, lambda { |reordering_request|
      LoadService.new.reorder_planning_orders(reordering_request) })
  end

  def submit_orders
    process_update_load_request(submit_return_orders_request, lambda { |submit_request|
      LoadService.new.submit_orders(submit_request) })
  end

  def complete_load
    process_update_load_request(date_shift_request, lambda { |request|
      LoadService.new.complete_load(request) })
  end

  def get_planning_orders
    process_collect_orders_request(lambda { |request|
      OrderReleaseService.new.collect_planning_orders (request) })
  end

  def get_available_orders
    process_collect_orders_request(lambda { |request|
      OrderReleaseService.new.collect_available_orders (request) })
  end

  private

  def process_collect_orders_request (processing_action)
    authorize_operation! :load_planning
    orders_response = processing_action.call(collect_orders_request)
    orders_response.set_draw params[:draw].to_i
    send_json_response(orders_response.to_json)
  end

  def process_update_load_request(request, processing_action)
    authorize_operation! :load_planning
    begin
      processing_action.call(request)
      data = process_success_response
    rescue LoadConstructingException => e
      data = {:status => 'fail', :message => e.message}
    end

    send_json_response(data)
  end

  def send_json_response (json_response)
    respond_to do |format|
      puts json_response
      format.json { render :json => json_response }
    end
  end

  def date_shift_request
    DateShiftRequest.new(get_delivery_date, get_delivery_shift)
  end

  def collect_orders_request
    OrdersCollectingRequest.new(required_columns, params.require(:start), params.require(:length), get_request_date, get_request_shift)
  end

  def submit_return_orders_request
    order_ids = params.require(:orders)
    truck_id = params.require(:truck)

    numeric_order_ids = []
    order_ids.each do |order_id|
      numeric_order_ids<<order_id.to_i
    end

    SubmitReturnRequest.new(get_request_date, get_request_shift, numeric_order_ids, truck_id)
  end

  def reorder_request
    OrdersReorderingRequest.new(params.require(:order_id).to_i, params.require(:old_position).to_i, params.require(:new_position).to_i)
  end

  def split_order_request
    SplitOrderRequest.new(params.require(:order_id).to_i, params.require(:new_quantity).to_i, params.require(:new_volume).to_i)
  end

  def process_success_response
    {:status => 'success'} #, :load_status => load.status.humanize, :truck_volume => '%.2f' % load.delivering_total_volume}
  end

  def process_warning_response(message)
    {:status => 'warning', :message => message}
  end

  def authorize_operation! op
    authorize! op, Load
  end

  def required_columns
    [:id,
     :delivery_shift,
     :delivery_date,
     :destination_name,
     :origin_name,
     :origin_raw_line_1,
     :destination_raw_line_1,
     :purchase_order_number,
     :volume, :handling_unit_quantity]
  end

  def get_request_date
    Date.strptime(params.require(:delivery_date), "%m/%d/%Y")
  end

  def get_request_shift
    Load.delivery_shifts[params.require(:delivery_shift)]
  end
end
