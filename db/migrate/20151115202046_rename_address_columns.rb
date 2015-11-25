class RenameAddressColumns < ActiveRecord::Migration
  def change
    rename_column :order_releases, :origin_raw_line, :origin_raw_line_1
    rename_column :order_releases, :destination_raw_line, :destination_raw_line_1
  end
end
