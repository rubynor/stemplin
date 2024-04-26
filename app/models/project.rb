class Project < ApplicationRecord
  include RateConvertible

  validates :name, presence: true, length: { minimum: 2, maximum: 30 }, uniqueness: { scope: :client }
  validates :description, presence: true, length: { minimum: 2, maximum: 100 }
  validates :rate, numericality: { only_integer: true }

  belongs_to :client
  has_one :organization, through: :client
  has_many :assigned_tasks, dependent: :destroy
  has_many :time_regs, through: :assigned_tasks
  has_many :tasks, through: :assigned_tasks
  has_many :time_regs, through: :assigned_tasks
end
