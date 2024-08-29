class TimeRegPolicy < ApplicationPolicy
  %i[ edit update destroy toggle_active export ].each do |action|
    define_method("#{action}?") do
      is_admin_allowed = user.organization_admin? && record.organization == user.current_organization
      user == record.user || is_admin_allowed
    end
  end

  %i[ index new_modal edit_modal update_tasks_select ].each do |action|
    define_method("#{action}?") do
      !user.access_info.organization_spectator?
    end
  end

  def create?
    return false if user.access_info.organization_spectator? || user != record.user
    record.organization.nil? ? true : user.current_organization == record.organization
  end

  scope_for :relation do |relation|
    organization = user.current_organization
    if user.organization_admin?
      relation.joins(:organization).where(organizations: organization).distinct
    elsif user.access_info.organization_spectator?
      projects = authorized_scope(Project.all, type: :relation).all
      relation.joins(:project).where(projects: projects).distinct
    else
      relation.joins(:organization, :user).where(organizations: organization, users: user).distinct
    end
  end

  scope_for :relation, :own do |relation|
    organization = user.current_organization
    relation.joins(:organization, :user).where(organizations: organization, users: user).distinct
  end
end
