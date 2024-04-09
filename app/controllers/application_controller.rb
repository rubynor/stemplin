class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  layout :layout_by_resource

  verify_authorized unless: :devise_controller?

  rescue_from ActionPolicy::Unauthorized do |ex|
    redirect_to root_path
  end


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
end
