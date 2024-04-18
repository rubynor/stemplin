class AlterProjects < ActiveRecord::Migration[7.0]
  def change
    remove_column :projects, :startdate
    rename_column :projects, :billable_project, :billable
    rename_column :projects, :billable_rate, :rate
  end
end
