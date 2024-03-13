class UserReport < ApplicationRecord
  validates_presence_of :timeframe, :user_id, :group_by, :task_ids
  validate :timeframe_dates_present, if: :custom_timeframe?
  validate :validate_project_ids_presence
  validate :valdiate_task_ids_presence

  # custom validations

  def custom_timeframe?
    timeframe == "custom"
  end

  def timeframe_dates_present
    return unless date_start.blank? || date_end.blank?

    errors.add(:custom_timeframe, "requires both start and end dates to be present")
  end

  def validate_project_ids_presence
    return unless project_ids.blank? || project_ids.all?(&:empty?)

    errors.add(:project_ids, "Please select atleast one project")
  end

  def valdiate_task_ids_presence
    return unless task_ids.blank? || task_ids.all?(&:empty?)

    errors.add(:task_ids, "Please select atleast one task")
  end
end
