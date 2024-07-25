class AssignedTask < ApplicationRecord
  include RateConvertible

  self.ignored_columns += [ "name" ]

  belongs_to :project
  belongs_to :task
  has_one :organization, through: :task
  has_many :time_regs, dependent: :destroy
  has_many :users, through: :time_regs

  validates :rate, numericality: { only_integer: true }

  validate :is_not_archived, on: :update

  accepts_nested_attributes_for :task

  before_update :handle_rate_change

  after_destroy :destroy_task_if_no_assigned_tasks

  scope :active_task, -> { where(is_archived: false) }

  def updated_active_task
    self.class.where(project: project, task: task).active_task.first
  end

  def destroy
    if self.time_regs.any?
      self.update_attribute(:is_archived, true)
    else
      super
    end
  end

  private

  def is_not_archived
    errors.add(:base, I18n.t("common.archived_task_can_not_be_updated")) if is_archived?
  end

  def handle_rate_change
    if rate_changed?
      self.class.create!(project: project, task: task, rate: rate)
      self.is_archived = true
      self.rate = rate_was
    end
  end

  def destroy_task_if_no_assigned_tasks
    task.destroy if task.assigned_tasks.empty? && task.time_regs.empty?
  end
end
