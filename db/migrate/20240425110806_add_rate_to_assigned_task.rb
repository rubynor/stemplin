class AddRateToAssignedTask < ActiveRecord::Migration[7.0]
  def change
    add_column :assigned_tasks, :rate, :integer, default: 0, null: false
  end
end
