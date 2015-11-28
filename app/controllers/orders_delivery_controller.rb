class OrdersDeliveryController < BaseLoadController
  def index
    authorize! :orders_delivery, Load
    @load = LoadService.new.get_load_for_driver(today_date_shift_request, current_user.id).load
  end

  def get_delivery_data
    authorize! :orders_delivery, Load
    response = LoadService.new.get_load_for_driver(date_shift_request, current_user.id)
    response.set_draw params[:draw].to_i
    send_json_response(response.to_json)
  end

  def download_routing_list
    authorize! :orders_delivery, Load

    request = date_shift_request
    load_response = LoadService.new.get_load_for_driver(request, current_user.id)
    order_releases =load_response.load.order_releases
    respond_to do |format|
      format.csv {
        send_data OrderReleaseService.new.to_csv(order_releases, csv_required_columns)
      }
    end
  end

  private

  def csv_required_columns
    ['stop_order_number',
     'purchase_order_number',
     'delivery_type',
     'volume',
     'handling_unit_quantity',
     'origin_raw_line_1',
     'destination_raw_line_1',
     'phone_number']
  end
end
