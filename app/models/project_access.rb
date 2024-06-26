class ProjectAccess < ApplicationRecord
  belongs_to :project
  belongs_to :access_info
  has_one :organization, through: :access_info

  validates :project_id, uniqueness: { scope: :access_info_id }
  validate :user_is_project_restricted

  private

  def user_is_project_restricted
    unless access_info.project_restricted?
      errors.add(:access_info, "User is not project restricted and can not have any ProjectAccesses.")
    end
  end
end
