class ClientPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.organization == user.current_organization
  end

  def create?
    user.organization_admin? && record.organization == user.current_organization
  end

  alias_method :new_modal?, :create?

  def update?
    user.organization_admin? && record.organization == user.current_organization
  end

  alias_method :edit_modal?, :update?

  def destroy?
    user.organization_admin? && record.organization == user.current_organization
  end

  scope_for :relation do |relation|
    organization = user.current_organization
    if user.organization_admin?
      relation.where(organization: organization)
    else
      projects = authorized_scope(organization.projects, type: :relation)
      relation.where(organization: organization)
        .joins(:projects)
        .where(projects: projects)
        .distinct
    end
  end
end
