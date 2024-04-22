class LocaleController < ApplicationController

    
  def set_locale
    option = params[:locale]
    case option
    when "nb"
        update_locale_and_redirect("nb")
    when "en"
        update_locale_and_redirect("en")
    end
  end

  private

  def update_locale_and_redirect(locale)
    current_user.update!(locale: locale)
    redirect_back(fallback_location: root_path(locale: locale))
  end
end
