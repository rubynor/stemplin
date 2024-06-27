class Project < ApplicationRecord
  include RateConvertible

  validates :name, presence: true, length: { minimum: 2, maximum: 30 }, uniqueness: { scope: :client }
  validates :description, length: { maximum: 100 }
  validates :rate, numericality: { only_integer: true }

  belongs_to :client
  has_one :organization, through: :client
  has_many :assigned_tasks, dependent: :destroy
  has_many :time_regs, through: :assigned_tasks
  has_many :tasks, through: :assigned_tasks
  has_many :time_regs, through: :assigned_tasks
  has_many :active_assigned_tasks, -> { active_task }, class_name: "AssignedTask"
  has_many :project_accesses, dependent: :destroy
  has_many :access_infos, through: :project_accesses
  has_many :users, through: :access_infos

  def update_tasks(task_ids)
    task_ids = task_ids.reject(&:empty?).map(&:to_i)
    current_task_ids = tasks.active.ids
    task_ids_to_remove = current_task_ids - task_ids
    task_ids_to_add = task_ids - current_task_ids

    assigned_tasks.where(task_id: task_ids_to_remove, is_archived: false).update_all(is_archived: true)
    task_ids_to_add.each do |id_to_add|
      assigned_tasks.create(task_id: id_to_add)
    end
  end
end
