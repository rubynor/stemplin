class TaskPolicy < ApplicationPolicy
  [ :index?, :show?, :new?, :create?, :edit?, :update?, :destroy? ].each do |action|
    define_method(action) { user.admin? && user.current_organization == record.organization }
  end

  scope_for :relation, :own do |relation|
    organization = user.current_organization
    users_projects = authorized_scope(Project.all, type: :relation).all
    relation.joins(:projects).where(projects: users_projects).distinct
  end

  scope_for :relation do |relation|
    if user.organization_admin?
      relation.where(organization: user.current_organization)
    else
      relation.joins(:users).where(organization: user.current_organization, users: user).distinct
    end
  end
end
