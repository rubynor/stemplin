class CreatePayrollPayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :payroll_payouts do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :period, null: false
      t.integer :status, null: false, default: 0
      t.integer :minutes, null: false
      t.decimal :hours, precision: 8, scale: 2, null: false
      t.decimal :hourly_wage, precision: 12, scale: 2, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.bigint :tripletex_employee_id, null: false
      t.bigint :tripletex_transaction_id
      t.bigint :tripletex_payslip_id
      t.references :sent_by, null: false, foreign_key: { to_table: :users }
      t.datetime :sent_at
      t.text :error_message
      t.timestamps
    end
    add_index :payroll_payouts, [ :organization_id, :user_id, :period ], unique: true, name: "index_payroll_payouts_on_organization_user_period"
  end
end
