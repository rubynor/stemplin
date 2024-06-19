class ProjectAccess < ApplicationRecord
  belongs_to :project
  belongs_to :access_info
  has_one :organization, through: :access_info
end
