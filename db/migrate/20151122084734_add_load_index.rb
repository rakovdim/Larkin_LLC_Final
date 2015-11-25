class AddLoadIndex < ActiveRecord::Migration
  def change
    add_index(:loads, [:delivery_date, :delivery_shift], name: 'delivery_date_shift_load_index')
  end
end
