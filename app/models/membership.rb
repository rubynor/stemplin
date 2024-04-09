class Membership < ApplicationRecord
  has_many :time_regs, dependent: :destroy
  belongs_to :user
  belongs_to :project
  has_one :organization, through: :project
end
