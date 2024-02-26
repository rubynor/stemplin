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
    groups = group_time_regs_by_keys(time_regs, *keys)
    children = time_reg_groups_to_report_children(groups)
    { title: title, children: children, total: sum_children_minutes(children) }
  end

  def group_time_regs_by_keys(time_regs, *group_keys)
    return time_regs if group_keys.empty?

    key = group_keys.first
    remaining_keys = group_keys[1..]

    time_regs.group_by { |item| item[key] }.to_h do |group_key, group_data|
      [group_key, group_time_regs_by_keys(group_data, *remaining_keys)]
    end
  end

  def time_reg_groups_to_report_children(grouped_time_regs)
    return {} if grouped_time_regs.blank?

    def recursive_report_children(data)
      return if data.blank?

      if !data.is_a?(Hash)
        sum_children_minutes(data)
      else
        data.map do |key, value|
          result = recursive_report_children(value)
          if result.is_a?(Array)
            { title: key, minutes: sum_children_minutes(result), children: result }
          else
            { title: key, minutes: result }
          end
        end
      end
    end

    recursive_report_children(grouped_time_regs)
  end
  def sum_children_minutes(struct)
    struct.sum { |child| child[:minutes] }
  end
end
