class OrderReleaseDropDeliveryType < ActiveRecord::Migration
  def change
    remove_column :order_releases, :delivery_type
  end
end
