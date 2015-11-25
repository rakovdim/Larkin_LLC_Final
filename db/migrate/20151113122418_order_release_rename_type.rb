class OrderReleaseRenameType < ActiveRecord::Migration
  def change
    rename_column :order_releases, :type, :delivery_type
  end
end
