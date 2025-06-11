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

  def active_timer_head(title_minutes)
    safe_join([
      tag.title(title_minutes + " | Stemplin", data: { refresh_minutes_target: "title" }),
      favicon_link_tag("rotate-time-glass.gif")
    ])
  end

  def default_head
    title_text = content_for?(:title) ? "#{yield(:title)} | Stemplin" : "Stemplin"
    safe_join([
      tag.title(title_text),
      favicon_link_tag("stemplin-ico-squared.svg")
    ])
  end

  def should_render_back_button?
    referer = request.referer
    return false if referer.blank?

    uri = URI.parse(referer)
    uri.host == request.host

  rescue URI::InvalidURIError
    false
  end
end
