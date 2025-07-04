module Workspace
  class AccessInfoPolicy < WorkspacePolicy
    scope_for :relation do |relation|
      if user.organization_admin?
        relation.joins(:organization).where(organizations: { id: user.current_organization.id }).distinct
      else
        relation.none
      end
    end
  end
end
