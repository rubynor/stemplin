class CreateProjectShares < ActiveRecord::Migration[8.1]
  def change
    create_table :project_shares do |t|
      t.references :project, null: false, foreign_key: true
      # The organization the project is shared with. Unknown until the invitation is accepted,
      # because the recipient picks which of their organizations the project goes into.
      t.references :organization, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :invited_email, null: false
      t.string :invitation_token, null: false
      t.integer :status, null: false, default: 0
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.datetime :rejected_at
      t.datetime :revoked_at
      t.timestamps

      t.index :invitation_token, unique: true
      t.index [ :project_id, :organization_id ], unique: true, where: "status = 1", name: "index_project_shares_on_accepted_project_and_organization"
      t.index [ :project_id, :invited_email ], unique: true, where: "status = 0", name: "index_project_shares_on_pending_project_and_email"
    end
  end
end
