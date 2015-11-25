class OrderReleasesController < ApplicationController

  def index
    authorize_operation! :index

    @order_releases = OrderRelease.paginate(page: params[:page], per_page: 10)
  end

  def show
    authorize_operation! :show

    @order_release = OrderRelease.find(params[:id])
  end

  def edit
    authorize_operation! :edit

    @order_release =OrderRelease.find(params[:id])
  end

  def update
    authorize_operation! :update

    @order_release = OrderRelease.find(params[:id])
    if @order_release.update(update_order_params)
      redirect_to @order_release
    else
      render 'edit'
    end
  end

  def save_orders
    authorize_operation! :save_orders

    #todo validations
    params[:data] = JSON.parse params[:data]
    converted_params = prepare_upload_order_params(upload_orders_params[:data])

    upload_response= OrderReleaseService.new.save_orders_bulk(converted_params)

    if upload_response.result
      flash[:success] = 'Orders were successfully uploaded'
      redirect_to action: :index
    else
      @order_releases = upload_response.invalid_orders
      render 'upload'
    end
  end

  private

  def authorize_operation! op
    authorize! op, OrderRelease
  end

  def upload_orders_params
    params.permit(data: order_permit_params)
  end

  def update_order_params
    params.require(:order_release).permit(order_permit_params)
  end

  def prepare_upload_order_params (orders_params)
    orders_params.delete_if { |params| params.nil? || params.empty? }
    orders_params.each do |one_order_params|
      one_order_params[:delivery_date] = get_delivery_date one_order_params[:delivery_date]
      one_order_params[:delivery_shift] = get_delivery_shift one_order_params[:delivery_shift]
      one_order_params[:mode] = get_mode one_order_params[:mode]
      one_order_params[:handling_unit_type] = get_unit_type one_order_params[:handling_unit_type]
    end
  end

  def get_delivery_shift (str)

    if str.nil? ||str.length == 0
      OrderRelease.delivery_shifts[:any_time]
    else
      case str
        when 'M' ||'m'
          OrderRelease.delivery_shifts[:morning]
        when 'N' ||'n'
          OrderRelease.delivery_shifts[:afternoon]
        when 'E' ||'e'
          OrderRelease.delivery_shifts[:evening]
        else
          #raise CSVFormatException, 'Incorrect format of delivery_shift field: '+str
          str
      end
    end
  end

  def get_delivery_date (delivery_date_str)
    if delivery_date_str.nil? || delivery_date_str.length == 0
      nil
    else
      begin
        Date.strptime(delivery_date_str, "%m/%d/%Y")
      rescue ArgumentError => e
        delivery_date_str
      end
    end
  end

  def get_unit_type (str)
    case str
      when 'box' || 'BOX'
        OrderRelease.handling_unit_types[:box]
      else
        #raise CSVFormatException, 'Incorrect format of handling_unit_type field: '+str
        str
    end
  end

  def get_mode (str)
    case str
      when 'TRUCKLOAD' || 'truckload'
        OrderRelease.modes[:TRUCKLOAD]
      else
        str
    end
  end

  def order_permit_params
    [:delivery_shift,
     :delivery_date,
     :origin_name,
     :origin_raw_line_1,
     :origin_city,
     :origin_state,
     :origin_zip,
     :origin_country,
     :destination_name,
     :destination_raw_line_1,
     :destination_city,
     :destination_state,
     :destination_zip,
     :destination_country,
     :phone_number,
     :mode,
     :purchase_order_number,
     :volume, :handling_unit_quantity, :handling_unit_type]
  end
end