class ValidateProjectInvitationsForeignKeys < ActiveRecord::Migration[7.1]
  def change
    validate_foreign_key :project_invitations, :projects
    validate_foreign_key :project_invitations, :users, column: :invited_by_id
    validate_foreign_key :project_invitations, :access_infos, column: :accepted_as_access_info_id
  end
end
