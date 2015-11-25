class AddMaxCapacityToTruck < ActiveRecord::Migration
  def change
    add_column :trucks, :max_capacity, :integer
  end
end
