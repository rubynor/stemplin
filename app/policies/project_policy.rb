class ProjectPolicy < ApplicationPolicy
  [ :show?, :new?, :create?, :edit?, :update?, :destroy?, :import? ].each do |action|
    define_method(action) { user.admin? }
  end

  scope_for :relation, :own do |relation|
    organization = user.organization
    relation.joins(:organization, :users).where(organizations: organization, users: user).distinct
  end

  scope_for :relation do |relation|
    organization = user.organization
    if user.admin?
      relation.joins(:organization).where(organizations: organization).distinct
    else
      relation.joins(:organization, :users).where(organizations: organization, users: user).distinct
    end
  end
end
