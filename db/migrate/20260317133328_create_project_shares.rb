class CreateProjectShares < ActiveRecord::Migration[7.1]
  def change
    create_table :project_shares do |t|
      t.references :project, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.integer :rate, default: 0, null: false

      t.timestamps
    end

    add_index :project_shares, [ :project_id, :organization_id ], unique: true
  end
end
