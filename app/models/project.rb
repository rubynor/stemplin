class Project < ApplicationRecord
  include Deletable

  self.ignored_columns = %w[rate billable]

  validates :name, presence: true, length: { minimum: 2, maximum: 60 }, uniqueness: { scope: :client, conditions: -> { where(discarded_at: nil) } }
  validates :description, length: { maximum: 100 }
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
  has_many :project_memberships
  has_many :organizations, through: :project_memberships

  after_create :create_owner_membership

  accepts_nested_attributes_for :assigned_tasks, allow_destroy: true

  attr_accessor :onboarding

  def onboarding?
    @onboarding
  end

  def rate
    owner_membership.rate
  end

  def rate=(rate)
    owner_membership.rate = rate
  end

  def rate_currency
    owner_membership.rate_currency
  end

  def rate_currency=(rate_in_currency)
    owner_membership.rate_currency=rate_in_currency
  end

  def billable
    owner_membership.billable
  end

  def billable=(billable)
    owner_membership.billable = billable
  end

  def owner_membership
    if project_memberships.all.any?
      project_memberships.find_by!(role: :owner)
    else
      project_memberships.to_a.find { |pm| pm.role.to_sym == :owner }
    end
  end

  def create_owner_membership
    if project_memberships.where(role: :owner).empty?
      project_memberships.create!(organization: client.organization, role: :owner)
    end
  end

  def must_have_at_least_one_active_assigned_task
    errors.add(:tasks, :blank) if assigned_tasks.to_a.reject { |assigned_task| assigned_task.marked_for_destruction? || assigned_task.is_archived }.empty?
  end
end
