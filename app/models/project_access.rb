class ProjectAccess < ApplicationRecord
  belongs_to :project
  belongs_to :access_info
  belongs_to :invited_by, class_name: "User", optional: true
  has_one :organization, through: :access_info

  validates :project_id, uniqueness: { scope: :access_info_id }
  validate :user_is_project_restricted
  validate :external_invitation_fields_present_if_external

  private

  def user_is_project_restricted
    unless access_info.project_restricted?
      errors.add(:access_info, "User is not project restricted and can not have any ProjectAccesses.")
    end
  end

  def external_invitation_fields_present_if_external
    if external?
      if invited_by_id.blank? || invitation_token.blank? || invited_at.blank?
        errors.add(:base, "External invitations must have invited_by, invitation_token, and invited_at")
      end
    end
  end

  def external?
    access_info.organization != project.organization
  end
end
