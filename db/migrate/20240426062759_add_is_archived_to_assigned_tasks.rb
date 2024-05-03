class AddIsArchivedToAssignedTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :assigned_tasks, :is_archived, :boolean, default: false
  end
end
