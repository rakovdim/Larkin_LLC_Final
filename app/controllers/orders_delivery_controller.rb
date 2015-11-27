class OrdersDeliveryController < BaseLoadController
  def index
    authorize! :orders_delivery, Load
    @load = LoadService.new.get_current_load_for_driver(current_user.id)
  end

  def get_delivery_data
    response = LoadService.new.get_load_for_driver(date_shift_request, current_user.id)
    response.set_draw params[:draw].to_i
    send_json_response(response.to_json)
  end

end
