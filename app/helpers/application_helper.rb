module ApplicationHelper
  def format_duration(total_minutes)
    hours = total_minutes / 60
    minutes = total_minutes % 60
    format("%02d:%02d", hours, minutes)
  end

  def format_date(date)
    date.strftime("%A, %d. %b")
  end
  def is_page_active?(page)
    Array(page).any? { |p| current_page?(p) }
  end

  def highlight_missing_translations
    content_tag(:style) do
      ".translation_missing { color: red;}"
    end
  end

  def show_svg(path)
    File.open("app/assets/images/#{path}", "rb") do |file|
      raw file.read
    end
  end
end
