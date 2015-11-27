class BaseLoadController < ApplicationController

  def date_shift_request
    DateShiftRequest.new(get_request_date, get_request_shift)
  end

  def get_request_date
    Date.strptime(params.require(:delivery_date), "%m/%d/%Y")
  end

  def get_request_shift
    Load.delivery_shifts[params.require(:delivery_shift)]
  end

  def send_json_response (json_response)
    respond_to do |format|
      puts json_response
      format.json { render :json => json_response }
    end
  end
end