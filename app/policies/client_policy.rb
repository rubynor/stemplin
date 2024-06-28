class ClientPolicy < ApplicationPolicy
  scope_for :relation do |relation|
    organization = user.current_organization
    projects = authorized_scope(organization.projects, type: :relation)
    if user.organization_admin?
      relation.where(organization: organization)
    else
      relation.where(organization: organization)
        .joins(:projects)
        .where(projects: projects)
        .distinct
    end
  end
end
