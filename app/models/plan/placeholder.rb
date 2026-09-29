module Plan
  # A named, unstaffed seat on the schedule ("Designer", "Senior backend") that
  # can hold assignments until a real person is found.
  class Placeholder < ApplicationRecord
    belongs_to :organization
    has_many :assignments, dependent: :destroy

    validates :name, presence: true, length: { maximum: 60 }
    validates :roles, length: { maximum: 200 }
  end
end
