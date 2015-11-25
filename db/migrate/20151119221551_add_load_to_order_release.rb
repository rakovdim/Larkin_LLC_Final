class AddLoadToOrderRelease < ActiveRecord::Migration
  def change
    add_reference :order_releases, :load, index: true, foreign_key: true
  end
end
