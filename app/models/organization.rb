class Organization < ApplicationRecord
  has_many :clients
  has_many :tasks
  has_many :access_infos
  has_many :users, through: :access_infos
  has_many :assigned_tasks, through: :tasks
  has_many :projects, through: :clients
  has_many :time_regs, through: :users
  has_many :plan_assignments, class_name: "Plan::Assignment", dependent: :destroy
  has_many :plan_milestones, class_name: "Plan::Milestone", dependent: :destroy
  has_many :plan_placeholders, class_name: "Plan::Placeholder", dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validate :currency_exists
  validates :plan_default_capacity_minutes, numericality: { only_integer: true, in: 0..(7 * 24 * 60) }

  def currency_exists
    errors.add(:currency, "is not a valid currency") unless Stemplin.config.currencies.keys.include?(self.currency&.to_sym)
  end
end
