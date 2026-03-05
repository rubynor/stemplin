class AddDateWorkedToTimeReg < ActiveRecord::Migration[7.0]
  def change
    add_column :time_regs, :date_worked, :date
  end
end
