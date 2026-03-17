class AddUniqueIndexToAccessInfos < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :access_infos, [ :user_id, :organization_id ], unique: true, algorithm: :concurrently
  end
end
