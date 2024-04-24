class AssignedTaskPolicy < ApplicationPolicy
  [ :new?, :create?, :destroy? ].each do |action|
    define_method(action) { user.admin? && user.current_organization == record.organization }
  end

  scope_for :relation do |relation|
    organization = user.current_organization
    if user.admin?
      relation.joins(:organization).where(organizations: organization).distinct
    else
      authorized_projects = authorized_scope(Project.all, type: :relation)
      relation.joins(:organization, :project).where(organizations: organization, projects: authorized_projects).distinct
    end
  end
end
