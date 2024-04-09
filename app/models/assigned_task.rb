class AssignedTask < ApplicationRecord
  belongs_to :project
  belongs_to :task
  has_one :organization, through: :task

  has_many :time_regs, dependent: :destroy
  has_many :users, through: :time_regs
end
