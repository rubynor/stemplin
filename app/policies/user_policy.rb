class UserPolicy < ApplicationPolicy
  scope_for :relation do |relation|
    if user.organization_admin?
      relation.joins(:organizations).where(organizations: { id: user.current_organization.id }).distinct
    elsif user.access_info.organization_spectator?
      projects = authorized_scope(Project.all, type: :relation).all
      relation.joins(time_regs: :project).where(projects: projects).distinct
    else
      relation.joins(:organizations).where(organizations: { id: user.current_organization.id }, id: user.id).distinct
    end
  end
end
