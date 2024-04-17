class Organization < ApplicationRecord
  has_many :clients
  has_many :tasks
  has_many :users
  has_many :assigned_tasks, through: :tasks
  has_many :memberships, through: :users
  has_many :projects, through: :clients
  has_many :time_regs, through: :users
end
