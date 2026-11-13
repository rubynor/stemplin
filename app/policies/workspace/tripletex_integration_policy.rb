module Workspace
  class TripletexIntegrationPolicy < WorkspacePolicy
    %i[ new create update destroy ].each do |action|
      define_method("#{action}?") { user.organization_admin? && record.organization_id == user.current_organization.id }
    end
  end
end
