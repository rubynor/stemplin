class AddBillableRateToProject < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :billable_rate, :integer, null: false, default: 0
  end
end
