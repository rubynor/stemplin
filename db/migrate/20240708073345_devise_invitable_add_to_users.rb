class DeviseInvitableAddToUsers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    add_column :users, :invitation_token, :string
    add_column :users, :invitation_created_at, :datetime
    add_column :users, :invitation_sent_at, :datetime
    add_column :users, :invitation_accepted_at, :datetime
    add_column :users, :invitation_limit, :integer
    add_reference :users, :invited_by, polymorphic: true, index: false
    add_column :users, :invitations_count, :integer, default: 0
    add_index :users, :invitation_token, unique: true, algorithm: :concurrently
    add_index :users, :invited_by_id, algorithm: :concurrently
  end

  def down
    remove_index :users, :invited_by_id
    remove_index :users, :invitation_token
    remove_reference :users, :invited_by, polymorphic: true
    remove_column :users, :invitations_count
    remove_column :users, :invitation_limit
    remove_column :users, :invitation_accepted_at
    remove_column :users, :invitation_sent_at
    remove_column :users, :invitation_created_at
    remove_column :users, :invitation_token
  end
end
