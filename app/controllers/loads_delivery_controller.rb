class LoadsDeliveryController < ApplicationController

  def list
    authorize! :list, :User
  end
end
