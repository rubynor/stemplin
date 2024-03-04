class AddBillableProjectToProject < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :billable_project, :boolean, null: false, default: false
  end
end
