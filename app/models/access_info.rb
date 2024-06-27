class AccessInfo < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  has_many :project_accesses, dependent: :destroy
  has_many :projects, through: :project_accesses

  enum role: { organization_user: 0, organization_admin: 1, super_admin: 2 }

  validates :user, presence: true
  validates :organization, presence: true
  validates :user_id, uniqueness: { scope: :organization_id }
  validate :no_project_accesses_unless_project_restricted

  def no_project_accesses_unless_project_restricted
    if !project_restricted? && project_accesses.any?
      errors.add(:project_accesses, "Cannot have project accesses if not project restricted")
    end
  end

  def self.allowed_organization_roles
    self.roles.except(:super_admin).keys
  end

  def self.project_restricted_roles
    self.roles.except(:super_admin, :organization_admin).keys
  end

  def project_restricted?
    self.class.project_restricted_roles.include? self.role
  end
end
