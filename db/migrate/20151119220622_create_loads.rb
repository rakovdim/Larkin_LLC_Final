class CreateLoads < ActiveRecord::Migration
  def change
    create_table :loads do |t|
      t.date :delivery_date
      t.integer :delivery_shift
      t.integer :status
      t.belongs_to :truck, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
