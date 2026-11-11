module Workspace
  class IntegrationsController < WorkspaceController
    def show
      @organization = current_user.current_organization
      authorize! @organization
      @tripletex_integration = @organization.tripletex_integration
    end

    private

    def implicit_authorization_target
      Organization
    end
  end
end
