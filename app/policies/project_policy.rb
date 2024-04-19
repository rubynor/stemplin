class ProjectPolicy < ApplicationPolicy
  [ :show?, :new?, :edit?, :update?, :destroy?, :import? ].each do |action|
    define_method(action) { user.organization_admin? && user.current_organization == record.organization }
  end

  def create?
    user.organization_admin? && user.current_organization == record.organization
  end

  scope_for :relation, :own do |relation|
    relation.joins(:organization, :users).where(organizations: user.current_organization, users: user).distinct
  end

  scope_for :relation do |relation|
    if user.organization_admin?
      relation.joins(:organization).where(organizations: user.current_organization).distinct
    else
      relation.joins(:organization, :users).where(organizations: user.current_organization, users: user).distinct
    end
  end
end
