class ProjectMembership < ApplicationRecord
  include RateConvertible
  include Deletable

  enum role: { guest: 0, owner: 1 }

  validates :rate, numericality: { only_integer: true }
  validates :project_id, uniqueness: { scope: :organization_id, conditions: -> { where(discarded_at: nil) } }
  validate :project_has_exactly_one_owner

  belongs_to :project
  belongs_to :organization

  private

  def project_has_exactly_one_owner
    return unless project && role == "owner"

    other_owners_query = project.project_memberships.where(role: :owner).where(discarded_at: nil)
    other_owners_query = other_owners_query.where.not(id: id) if persisted?
    
    if other_owners_query.exists?
      errors.add(:role, "Project can only have one owner organization")
    end
  end
end
