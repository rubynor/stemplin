class Project < ApplicationRecord
  validates :name, presence: true, length: { minimum: 2, maximum: 30 }, uniqueness: true
  validates :description, presence: true, length: { minimum: 2, maximum: 100 }
  validates :billable_rate, numericality: { only_integer: true }

  belongs_to :client
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :time_regs, through: :memberships
  has_many :assigned_tasks, dependent: :destroy
  has_many :tasks, through: :assigned_tasks

  def billable_rate_nok
    ConvertKroneOre.out(billable_rate)
  end

  def billable_rate_nok=(rate_in_nok)
    self.billable_rate = ConvertKroneOre.in(rate_in_nok)
  end
end
