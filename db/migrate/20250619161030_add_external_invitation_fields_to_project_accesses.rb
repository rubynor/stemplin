class AddExternalInvitationFieldsToProjectAccesses < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_column :project_accesses, :invited_by_id, :bigint
    add_column :project_accesses, :invitation_token, :string
    add_column :project_accesses, :invited_at, :datetime
    add_column :project_accesses, :accepted_at, :datetime

    add_index :project_accesses, :invitation_token, unique: true, algorithm: :concurrently
    add_foreign_key :project_accesses, :users, column: :invited_by_id, validate: false, algorithm: :concurrently
    validate_foreign_key :project_accesses, :users, column: :invited_by_id
  end

  def down
    remove_foreign_key :project_accesses, column: :invited_by_id
    remove_index :project_accesses, :invitation_token

    remove_column :project_accesses, :accepted_at, :datetime
    remove_column :project_accesses, :invited_at, :datetime
    remove_column :project_accesses, :invitation_token, :string
    remove_column :project_accesses, :invited_by_id, :bigint
  end
end
