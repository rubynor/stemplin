class AddDiscardedAtToProjects < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :projects, :discarded_at, :datetime
    add_index :projects, :discarded_at, algorithm: :concurrently
  end
end
