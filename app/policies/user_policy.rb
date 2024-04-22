class UserPolicy < ApplicationPolicy
  scope_for :relation do |relation|
    if user.organization_admin?
      relation.joins(:organizations).where(organizations: user.current_organization).distinct
    else
      relation.joins(:organizations).where(organizations: user.current_organization, id: user).distinct
    end
  end
end
