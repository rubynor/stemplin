class AssignedTask < ApplicationRecord
  include RateConvertible

  self.ignored_columns += [ "name" ]

  belongs_to :project
  belongs_to :task
  has_one :organization, through: :task
  has_many :time_regs, dependent: :destroy
  has_many :users, through: :time_regs

  validates :rate, numericality: { only_integer: true }

  accepts_nested_attributes_for :task

  before_update :handle_rate_change

  scope :active_task, -> { where(is_archived: false) }

  private

  def handle_rate_change
    if rate_changed?
      self.class.create!(project: project, task: task, rate: rate)
      self.is_archived = true
      self.rate = rate_was
    end
  end
end
