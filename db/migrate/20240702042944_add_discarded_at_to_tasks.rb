class AddDiscardedAtToTasks < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :tasks, :discarded_at, :datetime
    add_index :tasks, :discarded_at, algorithm: :concurrently
  end
end
