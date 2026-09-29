# The Plan module is Stemplin's resource scheduler: who works on which project,
# how many hours per day, and when. It is modelled on Harvest Forecast.
module Plan
  COLORS = %w[orange green aqua blue purple magenta red gray].freeze
  WEEKDAY_BITS = { monday: 0, tuesday: 1, wednesday: 2, thursday: 3, friday: 4, saturday: 5, sunday: 6 }.freeze
  DEFAULT_WORK_DAYS = 0b0011111

  def self.table_name_prefix
    "plan_"
  end

  # Whether `date` is a working day in the `work_days` bitmask.
  def self.work_day?(work_days, date)
    work_days[(date.cwday - 1)] == 1
  end

  def self.color_for(project)
    project.plan_color.presence || COLORS[project.id % COLORS.size]
  end
end
