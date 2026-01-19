class Organization < ApplicationRecord
  has_many :clients
  has_many :tasks
  has_many :access_infos
  has_many :users, through: :access_infos
  has_many :assigned_tasks, through: :tasks
  has_many :projects, through: :clients
  has_many :time_regs, through: :users

  validates :name, presence: true, uniqueness: true
  validates :holiday_country_code, inclusion: { in: proc { Holidays.available_regions.map(&:to_s) }, allow_nil: true }
  validate :currency_exists

  def currency_exists
    errors.add(:currency, "is not a valid currency") unless Stemplin.config.currencies.keys.include?(self.currency&.to_sym)
  end
end
