class AddNameToAssignedTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :assigned_tasks, :name, :string
  end
end
