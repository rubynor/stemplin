class Organization < ApplicationRecord
  has_many :clients
  has_many :tasks
  has_many :access_infos
  has_many :users, through: :access_infos
  has_many :assigned_tasks, through: :tasks
  has_many :projects, through: :clients
  has_many :time_regs, through: :users

  validates :name, presence: true, uniqueness: true
end
