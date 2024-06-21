class AccessInfo < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  has_many :project_accesses, dependent: :destroy
  has_many :projects, through: :project_accesses

  enum role: { organization_user: 0, organization_admin: 1, super_admin: 2 }

  validates :user, presence: true
  validates :organization, presence: true

  def self.allowed_organization_roles
    self.roles.except(:super_admin).keys
  end

  def project_restricted?
    self.organization_user?
  end
end
