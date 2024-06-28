class ClientPolicy < ApplicationPolicy
  %i[ show new create edit update destroy ].each do |action|
    define_method("#{action}?") { user.organization_admin? && user.organization == record.organization }
  end

  def index?
    user.organization_admin?
  end

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
