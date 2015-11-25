class AddOrderToOrderRelease < ActiveRecord::Migration
  def change
    add_column :order_releases, :stop_order_number, :integer
  end
end
