class CreateAccessInfo < ActiveRecord::Migration[7.0]
  def change
    create_table :access_infos do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.timestamps
    end
  end
end
