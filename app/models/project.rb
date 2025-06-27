class Project < ApplicationRecord
  include RateConvertible
  include Deletable

  validates :name, presence: true, length: { minimum: 2, maximum: 60 }, uniqueness: { scope: :client }
  validates :description, length: { maximum: 100 }
  validates :rate, numericality: { only_integer: true }
  validate :must_have_at_least_one_active_assigned_task, unless: :onboarding?

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
  has_many :project_invitations, dependent: :destroy

  accepts_nested_attributes_for :assigned_tasks, allow_destroy: true

  attr_accessor :onboarding

  def onboarding?
    @onboarding
  end

  def must_have_at_least_one_active_assigned_task
    errors.add(:tasks, :blank) if assigned_tasks.to_a.reject { |assigned_task| assigned_task.marked_for_destruction? || assigned_task.is_archived }.empty?
  end
end
