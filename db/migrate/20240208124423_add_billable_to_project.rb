class AddBillableToProject < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :billable, :boolean, default: false, null: false
  end
end
