module LocaleHandler
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  private

  def set_locale
    locale = params[:locale] || locale_from_current_user || session[:locale] || extract_locale_from_accept_language_header || I18n.default_locale

    begin
      I18n.locale = locale
    rescue I18n::InvalidLocale
      I18n.locale = I18n.default_locale
    end
    session[:locale] = I18n.locale
  end

  def locale_from_current_user
    current_user.try(:locale)
  end

  def extract_locale_from_accept_language_header
    browser_locales = request.env["HTTP_ACCEPT_LANGUAGE"]

    return unless browser_locales

    browser_locales.scan(/[a-z]{2}(?=[;|-])/).find do |locale|
      I18n.available_locales.include?(locale.to_sym)
    end
  end
end
