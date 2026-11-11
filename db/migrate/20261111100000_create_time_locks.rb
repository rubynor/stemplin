class CreateTimeLocks < ActiveRecord::Migration[8.1]
  def change
    create_table :time_locks do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :period, null: false
      t.references :locked_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :time_locks, [ :organization_id, :user_id, :period ], unique: true, name: "index_time_locks_on_organization_user_period"
  end
end
