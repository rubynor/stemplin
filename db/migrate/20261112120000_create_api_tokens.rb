class CreateApiTokens < ActiveRecord::Migration[8.1]
  def up
    create_table :api_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :token_digest, null: false
      t.timestamps
    end
    add_index :api_tokens, :token_digest, unique: true

    # Each user's single token becomes their first named one, so whatever
    # already holds it (the CLI, an MCP client) keeps working. The old column
    # stays behind, ignored by the model, the way users.api_token did.
    # One row per user who has a token: a small, single-statement copy.
    safety_assured do
      execute <<~SQL
        INSERT INTO api_tokens (user_id, name, token_digest, created_at, updated_at)
        SELECT id, 'Default', api_token_digest, NOW(), NOW()
        FROM users
        WHERE api_token_digest IS NOT NULL
      SQL
    end
  end

  def down
    drop_table :api_tokens
  end
end
