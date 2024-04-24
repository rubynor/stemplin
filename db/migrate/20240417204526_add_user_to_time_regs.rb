class AddUserToTimeRegs < ActiveRecord::Migration[7.0]
  def change
    add_reference :time_regs, :user, null: false, foreign_key: true
  end
end
