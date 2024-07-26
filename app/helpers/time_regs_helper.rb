module TimeRegsHelper
  # converts minutes to "0:00" format
  def convert_time_int(minutes)
    return nil if minutes.nil?

    hours = minutes / 60
    minutes = minutes % 60

    return "#{hours}:#{minutes}" if minutes > 9

    "#{hours}:0#{minutes}"
  end

  def minutes_by_day_of_week(date, user)
    start_of_week = date.beginning_of_week
    end_of_week = date.end_of_week

    time_regs = user.time_regs.where(date_worked: start_of_week..end_of_week)

    minutes_by_day = Hash.new(0)
    time_regs.each do |time_reg|
      day_of_week = time_reg.date_worked.strftime("%A")
      minutes_by_day[day_of_week] += time_reg.minutes
    end

    minutes_by_day
  end

  def active_text(time_reg)
    time_reg.new_record? ? t("common.create_time_reg") : t("common.update_time_reg")
  end

  def inactive_text(time_reg)
    return t("common.update_time_reg") if !time_reg.new_record?
    time_reg.date_worked == Date.today ? t("common.start_timer") : t("common.create_time_reg")
  end
end
