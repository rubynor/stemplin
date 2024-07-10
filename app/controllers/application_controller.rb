class ApplicationController < ActionController::Base
  include ActionView::RecordIdentifier
  include Pagy::Backend

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_locale
  before_action :redirect_if_no_organization
  layout :layout_by_resource

  verify_authorized unless: :devise_controller?

  rescue_from ActionPolicy::Unauthorized do |ex|
    redirect_to current_user&.access_info&.organization_spectator? ? report_path : root_path
  end

  def after_sign_in_path_for(resource)
    return new_onboarding_path if current_user.organizations.empty?
    return edit_password_onboarding_index_path unless current_user.is_verified?
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
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name])
    devise_parameter_sanitizer.permit(:accept_invitation, keys: %i[first_name last_name])
  end

  # data can either be a hash or a string
  def turbo_flash(type:, data:)
    flash.now[type] = data
    turbo_stream.replace "flash", partial: "shared/flash_messages"
  end

  def set_locale
    locale = params[:locale] || locale_from_current_user || extract_locale_from_accept_language_header || I18n.default_locale

    begin
      I18n.locale = locale
    rescue I18n::InvalidLocale
      I18n.locale = I18n.default_locale
    end
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

  def redirect_if_no_organization
    allowed_controllers = [ "onboarding", "invitations", "service_worker", "sessions" ]
    redirect_to new_onboarding_path if current_user&.organizations&.empty? && !allowed_controllers.include?(controller_name)
  end
end
