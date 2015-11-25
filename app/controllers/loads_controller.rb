class LoadsController < ApplicationController
  def index
    authorize_operation! :index
    @load = LoadService.new.get_current_load
    puts @load.delivering_total_volume
    @trucks = Truck.all
  end

  #todo validations
  def return_orders
    process_update_orders_request (submit_return_orders_request) { |return_request|
      LoadService.new.return_orders(return_request)
    }
  end

  def reorder_planning_orders
    process_update_orders_request (reorder_request) { |reordering_request|
      LoadService.new.reorder_planning_orders(reordering_request) }
  end

  #todo validations
  def submit_orders
    process_update_orders_request (submit_return_orders_request) { |submit_request|
      LoadService.new.submit_orders(submit_request) }
  end

  #todo validations
  def get_planning_orders
    authorize_operation! :get_planning_orders

    orders_response = OrderReleaseService.new.collect_planning_orders get_orders_request

    send_response orders_response
  end

  #todo validations
  def get_available_orders
    authorize_operation! :get_available_orders

    orders_response = OrderReleaseService.new.collect_available_orders get_orders_request

    send_response orders_response
  end

  def complete_load
    authorize_operation! :complete_load
    delivery_shift = Load.delivery_shifts[params[:delivery_shift]]
    delivery_date = params[:delivery_date]
    begin
      load = LoadService.new.complete_load(delivery_date, delivery_shift)
      data = load_op_success_response(load)
    rescue LoadConstructingException => e
      data = {:status => 'fail', :message => e.message}
    end
    puts data
    respond_to do |format|
      format.json { render :json => data }
    end
  end

  private

  def process_update_orders_request(request, &callback)
    authorize_operation! :update_orders
    begin
      load = callback.call(request)
      data = load_op_success_response(load)
    rescue LoadConstructingException => e
      data = {:status => 'fail', :message => e.message}
    end

    respond_to do |format|
      format.json { render :json => data }
    end
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

  def send_response (orders_response)
    orders_response.set_draw params[:draw].to_i
    respond_to do |format|
      json_response = orders_response.to_json
      puts json_response
      format.json { render :json => json_response }
    end
  end

  def get_orders_request
    delivery_shift = Load.delivery_shifts[params[:delivery_shift]]
    delivery_date = params[:delivery_date]
    OrdersRequest.new required_columns, params[:start], params[:length], delivery_date, delivery_shift
  end

  def submit_return_orders_request
    delivery_date = Date.strptime(params[:delivery_date], "%m/%d/%Y")
    delivery_shift = Load.delivery_shifts[params[:delivery_shift]]
    order_ids = params[:orders]
    truck_id = params[:truck]

    SubmitReturnRequest.new(delivery_date, delivery_shift, order_ids, truck_id)
  end

  def reorder_request
    OrderReorderingRequest.new(params[:order_id].to_i, params[:old_position].to_i, params[:new_position].to_i)
  end

  def load_op_success_response(load)
    {:status => 'success', :load_status => load.status.humanize, :truck_volume => '%.2f' % load.delivering_total_volume}
  end
end
