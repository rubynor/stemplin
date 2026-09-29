module Shared
  class ProjectSharePolicy < ApplicationPolicy
    def destroy?
      user.organization_admin? && record.accepted? && record.organization == user.current_organization
    end

    scope_for :relation do |relation|
      if user.organization_admin?
        relation.accepted.where(organization: user.current_organization)
      else
        relation.none
      end
    end
  end
end
