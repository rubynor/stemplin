module Plan
  # Plan-specific project settings (colour label, shifting the timeline).
  class ProjectSettingsPolicy < ApplicationPolicy
    def update?
      user.organization_admin? && record.organization == user.current_organization
    end

    alias_method :shift?, :update?
  end
end
