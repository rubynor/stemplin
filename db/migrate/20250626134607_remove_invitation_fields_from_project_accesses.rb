class RemoveInvitationFieldsFromProjectAccesses < ActiveRecord::Migration[7.1]
  def up
    remove_foreign_key :project_accesses, column: :invited_by_id
    remove_index :project_accesses, :invitation_token

    safety_assured do
      remove_column :project_accesses, :accepted_at, :datetime
      remove_column :project_accesses, :invited_at, :datetime
      remove_column :project_accesses, :invitation_token, :string
      remove_column :project_accesses, :invited_by_id, :bigint
    end
  end

  def down
    add_column :project_accesses, :invited_by_id, :bigint
    add_column :project_accesses, :invitation_token, :string
    add_column :project_accesses, :invited_at, :datetime
    add_column :project_accesses, :accepted_at, :datetime

    add_index :project_accesses, :invitation_token, unique: true
    add_foreign_key :project_accesses, :users, column: :invited_by_id
  end
end
