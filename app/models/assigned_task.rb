class AssignedTask < ApplicationRecord
  belongs_to :project
  belongs_to :task

  has_many :time_regs, dependent: :destroy

  validates :project_id, uniqueness: { scope: :task_id, message: "is already assigned to the project" }
  validates :task_id, presence: { message: "is required" }
end
