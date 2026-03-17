class Task < ApplicationRecord
  include Deletable

  validates :name, format: { without: /\r|\n/, message: "Line breaks are not allowed" }
  validates :name, presence: :true, length: { minimum: 2 }, uniqueness: { scope: :organization }

  has_many :assigned_tasks
  has_many :time_regs, through: :assigned_tasks
  has_many :projects, through: :assigned_tasks
  has_many :users, through: :time_regs
  belongs_to :organization

  scope :assigned_tasks, ->(project_id) { joins(:assigned_tasks).where(assigned_tasks: { project_id: project_id }).select("assigned_tasks.id AS id, tasks.name AS name") }
  scope :unassigned_tasks, ->(project_id) { where.not(id: AssignedTask.active_task.where(project_id: project_id).select(:task_id)) }

  scope :active, -> { joins(:assigned_tasks).where(assigned_tasks: { is_archived: false }).distinct }

  def self.assigned_task_names_and_ids(project_id)
    joins(:assigned_tasks)
      .where(assigned_tasks: { project_id: project_id })
      .merge(AssignedTask.active_task)
      .pluck(:name, "assigned_tasks.id")
  end
end
