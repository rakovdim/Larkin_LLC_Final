class CreateTrucks < ActiveRecord::Migration
  def change
    create_table :trucks do |t|
      t.string :name
      t.integer :driver_id

      t.timestamps null: false
    end
  end
end
