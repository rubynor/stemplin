class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_locale
  layout :layout_by_resource

  private

  def layout_by_resource
    if request.headers[:Turbo_Frame]
      nil
    else
      "application"
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name key])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name])
  end

  # data can either be a hash or a string
  def turbo_flash(type:, data:)
    flash[type] = data
    turbo_stream.replace "flash", partial: "shared/flash_messages"
  end

  def set_locale
    if current_user
      I18n.locale = current_user.locale
    else
      I18n.locale = I18n.default_locale
    end
  end
end
