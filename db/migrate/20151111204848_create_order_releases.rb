class CreateOrderReleases < ActiveRecord::Migration
  def change
    create_table :order_releases do |t|
      t.date :delivery_date
      t.integer :delivery_shift
      t.string :origin_name
      t.text :origin_raw_line
      t.string :origin_city
      t.string :origin_state
      t.string :origin_country
      t.integer :origin_zip
      t.string :destination_name
      t.text :destination_raw_line
      t.string :destination_city
      t.string :destination_state
      t.integer :destination_zip
      t.string :destination_country
      t.string :phone_number
      t.integer :mode
      t.string :purchase_order_number
      t.float :volume
      t.integer :handling_unit_quantity
      t.integer :handling_unit_type
      t.integer :status
      t.integer :type

      t.timestamps null: false
    end
  end
end
