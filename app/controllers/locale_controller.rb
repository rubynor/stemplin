class LocaleController < ApplicationController
  # Only ever touches current_user, so there is nothing to authorize.
  skip_verify_authorized

  before_action :authenticate_user!

  # Named `update` on purpose: LocaleHandler already registers a before_action
  # called `set_locale`, and an action with the same name would override it and
  # run before authentication.
  def update
    option = params[:locale]
    case option
    when "nb"
        update_locale_and_redirect("nb")
    when "en"
        update_locale_and_redirect("en")
    else
        redirect_back(fallback_location: root_path)
    end
  end

  private

  def update_locale_and_redirect(locale)
    current_user.update!(locale: locale)
    redirect_back(fallback_location: root_path(locale: locale))
  end
end
