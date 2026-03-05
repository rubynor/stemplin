class BackfillApiTokenDigest < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    safety_assured do
      enable_extension "pgcrypto"

      execute <<~SQL
        UPDATE users
        SET api_token_digest = encode(digest(api_token, 'sha256'), 'hex')
        WHERE api_token IS NOT NULL AND api_token_digest IS NULL
      SQL
    end
  end

  def down
    safety_assured do
      execute <<~SQL
        UPDATE users SET api_token_digest = NULL
      SQL
    end
  end
end
