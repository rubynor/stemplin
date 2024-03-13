class ProjectReport < ApplicationRecord
  validates_presence_of :timeframe, :client_id, :project_id, :group_by
  validate :timeframe_dates_present, if: :custom_timeframe?
  validate :validate_member_ids_presence
  validate :valdiate_task_ids_presence

  # custom validations

  def custom_timeframe?
    timeframe == "custom"
  end

  def timeframe_dates_present
    return unless date_start.blank? || date_end.blank?

    errors.add(:custom_timeframe, "requires both start and end dates to be present")
  end

  def validate_member_ids_presence
    return unless member_ids.blank? || member_ids.all?(&:empty?)

    errors.add(:member_ids, "Please select atleast one member")
  end

  def valdiate_task_ids_presence
    return unless task_ids.blank? || task_ids.all?(&:empty?)

    errors.add(:task_ids, "Please select atleast one task")
  end
end
