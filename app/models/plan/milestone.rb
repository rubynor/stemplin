module Plan
  class Milestone < ApplicationRecord
    belongs_to :organization
    belongs_to :project

    validates :name, presence: true, length: { maximum: 60 }
    validates :date, presence: true
    validate :project_in_organization

    scope :between_dates, ->(start_date, end_date) { where(date: start_date..end_date) }

    private

    def project_in_organization
      errors.add(:project, :invalid) if project && project.organization != organization
    end
  end
end
