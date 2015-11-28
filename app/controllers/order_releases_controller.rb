class OrderReleasesController < ApplicationController

  def index
    authorize_order_management!

    @order_releases = OrderRelease.paginate(page: params[:page], per_page: 15)
  end

  def show
    authorize_order_management!

    @order_release = OrderRelease.find(params[:id])
  end

  def edit
    authorize_order_management!

    @order_release =OrderRelease.find(params[:id])
  end

  def update
    authorize_order_management!
    @order_release = OrderRelease.find(params.require(:id))

    if @order_release.update(update_order_params)
      redirect_to @order_release
    else
      render 'edit'
    end
  end

  def save_orders
    authorize_order_management!

    params[:data] = JSON.parse params[:data]
    permitted_params = upload_orders_permitted_params[:data]

    upload_response= OrderReleaseService.new.save_orders_bulk(permitted_params)

    if upload_response.result
      flash[:success] = 'Orders were successfully uploaded'
      redirect_to action: :index
    else
      @order_releases = upload_response.invalid_orders
      render 'upload'
    end
  end

  private

  def authorize_order_management!
    authorize! :order_management, OrderRelease
  end

  def upload_orders_permitted_params
    params.permit(data: order_permit_params)
  end

  def update_order_params
    params.require(:order_release).permit(order_permit_params)
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