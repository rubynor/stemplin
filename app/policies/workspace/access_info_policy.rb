module Workspace
  class AccessInfoPolicy < WorkspacePolicy
    scope_for :relation do |relation|
      if user.organization_admin?
        relation.joins(:organizations).where(organizations: user.current_organization).distinct
      else
        relation.none
      end
    end
  end
end
