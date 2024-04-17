class ClientPolicy < ApplicationPolicy
  [ :show?, :new?, :create?, :edit?, :update?, :destroy? ].each do |action|
    define_method(action) { user.admin? && user.organization == record.organization }
  end

  def index?
    user.admin?
  end

  scope_for :relation do |relation|
    organization = user.organization
    if user.admin?
      relation.where(organization: organization)
    else
      relation.where(organization: organization)
        .joins(:projects)
        .where(projects: user.projects)
        .distinct
    end
  end
end
