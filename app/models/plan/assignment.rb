module Plan
  # Hours per working day that a person (or placeholder) is booked on a project
  # between two dates. An assignment without a project is time off.
  class Assignment < ApplicationRecord
    MAX_DAYS = 366 * 2

    belongs_to :organization
    belongs_to :project, optional: true
    belongs_to :user, optional: true
    belongs_to :placeholder, optional: true

    validates :start_date, :end_date, presence: true
    validates :minutes_per_day, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1440 }
    validates :notes, length: { maximum: 2000 }
    validate :exactly_one_assignee
    validate :end_after_start
    validate :assignee_and_project_in_organization

    scope :overlapping, ->(start_date, end_date) { where("start_date <= ? AND end_date >= ?", end_date, start_date) }
    scope :time_off, -> { where(project_id: nil) }

    def time_off?
      project_id.nil?
    end

    def work_days
      return Plan::DEFAULT_WORK_DAYS unless user

      user.all_access_infos.find_by(organization: organization)&.plan_work_days || Plan::DEFAULT_WORK_DAYS
    end

    # Number of the assignee's working days this assignment covers within the range.
    def working_days_between(range_start = start_date, range_end = end_date)
      from = [ start_date, range_start ].max
      to = [ end_date, range_end ].min
      return 0 if from > to

      mask = work_days
      (from..to).count { |date| Plan.work_day?(mask, date) }
    end

    def minutes_between(range_start, range_end)
      working_days_between(range_start, range_end) * minutes_per_day
    end

    # Cut this assignment in two; the second half starts on `date`.
    def split!(date)
      raise ArgumentError, "split date must be inside the assignment" unless date > start_date && date <= end_date

      transaction do
        second = dup
        second.start_date = date
        second.save!
        update!(end_date: date - 1)
        second
      end
    end

    private

    def exactly_one_assignee
      errors.add(:base, :one_assignee) unless user_id.present? ^ placeholder_id.present?
    end

    def end_after_start
      return unless start_date && end_date

      errors.add(:end_date, :before_start) if end_date < start_date
      errors.add(:end_date, :too_long) if (end_date - start_date).to_i > MAX_DAYS
    end

    def assignee_and_project_in_organization
      return unless organization

      errors.add(:project, :invalid) if project && project.organization != organization
      errors.add(:placeholder, :invalid) if placeholder && placeholder.organization_id != organization_id
      errors.add(:user, :invalid) if user && !user_member_of_organization?
    end

    # People who were archived or made spectators keep their existing bookings
    # (which can still be moved or trimmed), but can't be booked anew.
    def user_member_of_organization?
      memberships = user_id_changed? ? user.access_infos.plannable : user.all_access_infos
      memberships.exists?(organization: organization)
    end
  end
end
