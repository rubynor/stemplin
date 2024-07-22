class AddDiscardedAtToTimeRegs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :time_regs, :discarded_at, :datetime
    add_index :time_regs, :discarded_at, algorithm: :concurrently
  end
end
