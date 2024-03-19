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

  def format_date(date)
    date.strftime("%d/%m/%Y")
  end

  def user_names(users)
    users.map { |u| u.name }.join(", ")
  end

  def time_frame(start_date, end_date)
    return "All time" unless start_date && end_date
    "#{format_date(start_date)} - #{format_date(end_date)}"
  end

  def filter_check_box(checkbox, checked, options = {})
    checkbox.label(class: "bg-white px-3 py-1.5 rounded-sm") do
      checkbox_tag = checkbox.check_box(checked: checked, class: "mr-2", **options)
      label_text = checkbox.text

      "#{checkbox_tag} #{label_text}".html_safe
    end
  end
end
