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

  def link_to_back_or(url, **options, &block)
    dont_use_fallback = request.referer.present? && request.referer != request.original_url
    link_to((dont_use_fallback ? :back : url), **options, &block)
  end

  def render_back_button_if_needed
    referer = request.referer
    return if referer.blank?

    uri = URI.parse(referer)
    return unless uri.host == request.host

    link_to "javascript:history.back()", class: "w-10 h-10 rounded-full bg-gray-100 hover:bg-gray-200 flex justify-center items-center transition duration-300 ease-in-out print:hidden" do
      content_tag(:i, "&#xe833;".html_safe, class: "uc-icon text-2xl")
    end

  rescue URI::InvalidURIError
    nil
  end
end
