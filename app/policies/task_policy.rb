class TaskPolicy < ApplicationPolicy
  [ :index?, :show?, :new?, :create?, :edit?, :update?, :destroy? ].each do |action|
    define_method(action) { user.admin? }
  end

  scope_for :own do |relation|
    organization = user.organization
    relation.joins(:users).where(organization: organization, users: user).distinct
  end

  scope_for :relation do |relation|
    organization = user.organization
    if user.admin?
      relation.where(organization: organization)
    else
      relation.joins(:users).where(organization: organization, users: user).distinct
    end
  end
end
