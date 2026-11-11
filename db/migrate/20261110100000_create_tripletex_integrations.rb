class CreateTripletexIntegrations < ActiveRecord::Migration[8.1]
  def change
    create_table :tripletex_integrations do |t|
      t.references :organization, null: false, foreign_key: true, index: { unique: true }
      t.text :employee_token, null: false
      t.bigint :company_id
      t.string :company_name
      t.timestamps
    end
  end
end
