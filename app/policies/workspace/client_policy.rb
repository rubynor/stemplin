module Workspace
  class ClientPolicy < WorkspacePolicy
    scope_for :relation do |relation|
      if user.organization_admin?
        relation.where(organization: user.current_organization)
      else
        relation.none
      end
    end
  end
end
