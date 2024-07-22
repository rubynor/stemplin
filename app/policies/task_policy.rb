class TaskPolicy < ApplicationPolicy
  scope_for :relation, :own do |relation|
    users_projects = authorized_scope(Project.all, type: :relation).all
    relation.joins(:projects).where(projects: users_projects).distinct
  end

  scope_for :relation do |relation|
    if user.organization_admin?
      relation.where(organization: user.current_organization)
    elsif user.access_info.organization_spectator?
      projects = authorized_scope(Project.all, type: :relation).all
      relation.joins(:projects).where(projects: projects).distinct
    else
      relation.joins(:users).where(organization: user.current_organization, users: user).distinct
    end
  end
end
