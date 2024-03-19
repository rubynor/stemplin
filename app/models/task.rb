class Task < ApplicationRecord
  validates :name, format: { without: /\r|\n/, message: "Line breaks are not allowed" }
  validates :name, presence: :true, length: { minimum: 2, maximum: 50 }, uniqueness: true
  has_many :assigned_tasks
  has_many :time_regs, through: :assigned_tasks
  has_many :projects, through: :assigned_tasks
end
