module LocaleHandler
  extend ActiveSupport::Concern

  included do
    around_action :set_locale
  end

  private

  # Scoped to the request with `with_locale`, so the locale doesn't stay on the
  # thread and leak into whatever it runs next (another request, or a test).
  def set_locale(&action)
    locale = params[:locale] || locale_from_current_user || session[:locale] || extract_locale_from_accept_language_header || I18n.default_locale
    locale = I18n.default_locale unless I18n.locale_available?(locale)

    session[:locale] = locale.to_sym
    I18n.with_locale(locale, &action)
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
