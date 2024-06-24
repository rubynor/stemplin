class AccessInfo < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  enum role: { organization_user: 0, organization_admin: 1, super_admin: 2 }

  validates :user, presence: true
  validates :organization, presence: true
  validates :user_id, uniqueness: { scope: :organization_id }

  def self.allowed_organization_roles
    self.roles.except(:super_admin).keys
  end
end
