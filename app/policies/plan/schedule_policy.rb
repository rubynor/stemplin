module Plan
  # Everyone in an organization can look at the plan; only admins change it.
  # What a non-admin sees is narrowed by the scopes on the record policies.
  class SchedulePolicy < ApplicationPolicy
    def show?
      user.current_organization.present?
    end

    alias_method :export?, :show?

    def manage?
      user.organization_admin?
    end
  end
end
