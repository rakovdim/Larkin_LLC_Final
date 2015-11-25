class AddCapacityToTruck < ActiveRecord::Migration
  def change
    add_column :trucks, :capacity, :integer, :default => 1400
  end
end
