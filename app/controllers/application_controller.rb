class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authorize_admin!, unless: :devise_controller?
  layout :layout_by_resource

  def authorize_admin!
    redirect_to root_path unless current_user&.admin?
  end

  def available_clients
    return Client.none if current_user.nil?
    return Client.all if current_user.admin?
    current_user.clients.distinct
  end

  def available_projects
    return Project.none if current_user.nil?
    return Project.all if current_user.admin?
    current_user.projects.distinct
  end

  def available_tasks
    return Task.none if current_user.nil?
    return Task.all if current_user.admin?
    current_user.tasks.distinct
  end

  def available_users
    return User.none if current_user.nil?
    return User.all if current_user.admin?
    User.where(id: current_user.id)
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
