class ProjectAccess < ApplicationRecord
  belongs_to :project
  belongs_to :access_info
  has_one :organization, through: :access_info

  validates :project_id, uniqueness: { scope: :access_info_id, message: "This Project-AccessInfo relation already exists." }
end
