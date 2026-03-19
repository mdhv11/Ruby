class AddStandardHoursToDepartments < ActiveRecord::Migration[8.1]
  def change
    add_column :departments, :standard_hours, :decimal, precision: 4, scale: 1
  end
end