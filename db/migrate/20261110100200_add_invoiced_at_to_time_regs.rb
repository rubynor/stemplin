class AddInvoicedAtToTimeRegs < ActiveRecord::Migration[8.1]
  def change
    add_column :time_regs, :invoiced_at, :datetime
    add_column :time_regs, :tripletex_order_id, :bigint
  end
end
