class AddDefaultValueToTimeRegsMinutes < ActiveRecord::Migration[7.0]
  def up
    change_column :time_regs, :minutes, :integer, null: false, default: 0
  end

  def down
    change_column :time_regs, :minutes, :integer, null: true
  end
end
