class CreateProjectInvitations < ActiveRecord::Migration[7.1]
  def change
    create_table :project_invitations do |t|
      t.bigint :project_id, null: false
      t.string :invited_email, null: false
      t.bigint :invited_by_id, null: false
      t.string :invitation_token, null: false
      t.datetime :invited_at, null: false
      t.datetime :accepted_at
      t.datetime :rejected_at
      t.datetime :expires_at
      t.bigint :accepted_as_access_info_id
      t.timestamps

      t.index :invitation_token, unique: true
      t.index [ :invited_email, :project_id ], unique: true
      t.index :project_id
      t.index :accepted_as_access_info_id
    end

    add_foreign_key :project_invitations, :projects, validate: false
    add_foreign_key :project_invitations, :users, column: :invited_by_id, validate: false
    add_foreign_key :project_invitations, :access_infos, column: :accepted_as_access_info_id, validate: false
  end
end
