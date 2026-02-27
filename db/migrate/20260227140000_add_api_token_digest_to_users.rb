class AddApiTokenDigestToUsers < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :users, :api_token_digest, :string, if_not_exists: true
    add_index :users, :api_token_digest, unique: true, algorithm: :concurrently, if_not_exists: true
  end
end
