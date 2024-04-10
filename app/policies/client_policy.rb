class ClientPolicy < ApplicationPolicy
  [ :index?, :show?, :new?, :create?, :edit?, :update?, :destroy? ].each do |action|
    define_method(action) { user.admin? }
  end

  scope_for :relation do |relation|
    organization = user.organization
    if user.admin?
      relation.where(organization: organization)
    else
      relation.where(organization: organization)
        .where(organization: organization)
        .joins(:projects)
        .where(projects: user.projects)
        .distinct
    end
  end
end
