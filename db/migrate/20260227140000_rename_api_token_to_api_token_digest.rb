class RenameApiTokenToApiTokenDigest < ActiveRecord::Migration[7.1]
  def change
    rename_column :users, :api_token, :api_token_digest
  end
end
