module ReportsHelper
  # converts time-regs minutes to "0:00" format
  def convert_time_int(minutes)
    return nil if minutes.nil?

    hours = minutes / 60
    minutes = minutes % 60

    return "#{hours}:#{minutes}" if minutes > 9

    "#{hours}:0#{minutes}"
  end

  def minutes_to_float(minutes)
    number_with_precision((minutes / 60.0), precision: 2)
  end

  def report_data(title:, time_regs:, keys:)
    {
      title: title,
      children: time_reg_report(time_regs, keys),
      total: time_regs.sum { |time_reg| time_reg[:minutes] }
    }
  end

  def time_reg_report(time_regs, keys)
    key = keys.first

    return [] if key.blank?

    grouped_regs = time_regs.group_by { |time_reg| time_reg[key] }

    grouped_regs.map do |group, regs|
      {
        title: group,
        key: key,
        children: time_reg_report(regs, keys[1..]),
        minutes: regs.sum { |reg| reg[:minutes] }
      }
    end
  end
end
