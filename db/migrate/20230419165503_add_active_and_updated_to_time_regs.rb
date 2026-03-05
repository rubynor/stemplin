class AddActiveAndUpdatedToTimeRegs < ActiveRecord::Migration[7.0]
  def change
    add_column :time_regs, :active, :boolean
    add_column :time_regs, :updated, :datetime
  end
end
