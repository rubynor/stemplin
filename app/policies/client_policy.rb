class ClientPolicy < ApplicationPolicy
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
