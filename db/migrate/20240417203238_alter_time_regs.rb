class AlterTimeRegs < ActiveRecord::Migration[7.0]
  def change
    remove_column :time_regs, :membership_id
    remove_column :time_regs, :active
    remove_column :time_regs, :updated
    add_column :time_regs, :start_time, :timestamp, null: true
  end
end
