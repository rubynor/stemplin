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
    return false if user.access_info.organization_spectator?

    same_organization = user.current_organization == record.organization
    no_organization = record.organization.nil?

    if user.organization_admin?
      same_organization
    else
      (same_organization || no_organization) && record.user == user
    end
  end

  scope_for :relation do |relation|
    organization = user.current_organization
    if user.organization_admin?
      relation.joins(:organization).where(organizations: { id: organization.id }).distinct
    elsif user.access_info.organization_spectator?
      projects = authorized_scope(Project.all, type: :relation).all
      relation.joins(:project).where(projects: projects).distinct
    else
      relation.joins(:organization, :user).where(organizations: { id: organization.id }, users: { id: user.id }).distinct
    end
  end

  scope_for :relation, :own do |relation|
    organization = user.current_organization
    relation.joins(:organization, :user).where(organizations: { id: organization.id }, users: { id: user.id }).distinct
  end
end
