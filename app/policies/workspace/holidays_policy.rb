module Workspace
  class HolidaysPolicy < WorkspacePolicy
    def show?
      user.current_organization.present?
    end

    def update?
      user.organization_admin?
    end
  end
end
