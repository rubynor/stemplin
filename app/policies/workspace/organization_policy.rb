module Workspace
  class OrganizationPolicy < WorkspacePolicy
    %i[ show edit update ].each do |action|
      define_method("#{action}?") { user.organization_admin? && record.id == user.current_organization.id }
    end
  end
end
