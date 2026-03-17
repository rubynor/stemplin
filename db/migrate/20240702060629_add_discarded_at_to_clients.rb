class AddDiscardedAtToClients < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :clients, :discarded_at, :datetime
    add_index :clients, :discarded_at, algorithm: :concurrently
  end
end
