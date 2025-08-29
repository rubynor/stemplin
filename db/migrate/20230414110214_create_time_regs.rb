class CreateTimeRegs < ActiveRecord::Migration[7.0]
  def change
    create_table :time_regs do |t|
      t.text :notes
      t.integer :minutes
      t.references :membership, null: false, foreign_key: true
      t.references :assigned_task, null: false, foreign_key: true

      t.timestamps
    end
  end
end
