class HashExistingApiTokens < ActiveRecord::Migration[7.1]
  def up
    User.where.not(api_token_digest: nil).find_each do |user|
      user.update_column(:api_token_digest, Digest::SHA256.hexdigest(user.api_token_digest))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
