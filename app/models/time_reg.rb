class TimeReg < ApplicationRecord
  validates :notes, format: { without: /\r|\n/, message: "Line breaks are not allowed" }

  belongs_to :membership
  belongs_to :assigned_task
  has_one :project, through: :assigned_task
  has_one :task, through: :assigned_task, source: :task
  has_one :user, through: :membership

  validates :notes, length: { maximum: 255 }
  validates :minutes, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 }
  validates :membership, presence: true
  validates :assigned_task, presence: true
  validates :assigned_task_id, presence: true
  validates :date_worked, presence: true
end
