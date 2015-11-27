class AddIndexToOrderRelease < ActiveRecord::Migration
  def change
    #todo multicolumn index
    #todo index for load_id
    add_index :order_releases, :delivery_date
    add_index :order_releases, :delivery_shift
    add_index :order_releases, :status
  end
end
