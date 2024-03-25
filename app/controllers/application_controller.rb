class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authorize_admin!, unless: :devise_controller?
  layout :layout_by_resource

  def authorize_admin!
    redirect_to root_path unless current_user&.admin?
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
end
