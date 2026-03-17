class ProjectShare < ApplicationRecord
  include RateConvertible

  belongs_to :project
  belongs_to :organization

  has_many :project_share_task_rates, dependent: :destroy
  accepts_nested_attributes_for :project_share_task_rates

  validates :organization_id, uniqueness: { scope: :project_id }
  validate :organization_is_not_project_owner

  def rate_for_task(assigned_task)
    task_rate = project_share_task_rates.find_by(assigned_task: assigned_task)
    rate = task_rate&.rate || 0
    rate.positive? ? rate : self.rate
  end

  private

  def organization_is_not_project_owner
    errors.add(:organization, :is_project_owner) if organization_id == project&.organization&.id
  end
end
