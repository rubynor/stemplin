class AddApiTokenToUsers < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :users, :api_token, :string, if_not_exists: true
    add_index :users, :api_token, unique: true, algorithm: :concurrently, if_not_exists: true
  end
end
