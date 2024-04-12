class Membership < ApplicationRecord
  has_many :time_regs
  belongs_to :user
  belongs_to :project

  validates :user_id, uniqueness: { scope: :project_id, message: "is already a member of the project" }
  validates :user_id, presence: { message: "does not exist" }

  before_destroy :ensure_valid_deletion

  private

  def ensure_valid_deletion
    errors.add(:base, "Cannot remove last member of the project") if project.memberships.count <= 1
    errors.add(:base, "Member has time entries in this project") if time_regs.any?
    throw :abort if errors.any?
  end
end
