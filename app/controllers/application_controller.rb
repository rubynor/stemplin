class ApplicationController < ActionController::Base
  include ActionView::RecordIdentifier, Pagy::Backend
  include LocaleHandler, Authorization

  before_action :set_paper_trail_whodunnit
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :redirect_if_no_organization
  layout :layout_by_resource

  def after_sign_in_path_for(resource)
    return onboarding_wizard_path(:organization) if should_redirect_to_onboarding?
    root_path
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
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name locale])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: %i[first_name last_name locale])
  end

  # data can either be a hash or a string
  def turbo_flash(type:, data:)
    flash.now[type] = data
    turbo_stream.replace "flash", partial: "shared/flash_messages"
  end

  def redirect_if_no_organization
    redirect_to onboarding_wizard_path(:organization) if should_redirect_to_onboarding?
  end

  def should_redirect_to_onboarding?
    allowed_controllers = %w[onboarding_wizard invitations service_worker sessions]
    current_user&.organizations&.empty? && !allowed_controllers.include?(controller_name)
  end
end
