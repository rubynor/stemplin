class ProjectShareTaskRate < ApplicationRecord
  include RateConvertible

  belongs_to :project_share
  belongs_to :assigned_task

  validates :assigned_task_id, uniqueness: { scope: :project_share_id }
end
