class RemoveNameFromAssignedTasks < ActiveRecord::Migration[7.0]
  def change
    safety_assured { remove_column :assigned_tasks, :name }
  end
end
