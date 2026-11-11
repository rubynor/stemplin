module Workspace
  # Connects a workspace to Tripletex: the admin pastes an employee token, we verify it by
  # opening a session and reading the company it belongs to, then store it encrypted.
  class TripletexIntegrationsController < WorkspaceController
    before_action :set_organization

    def new
      @tripletex_integration = @organization.tripletex_integration || @organization.build_tripletex_integration
      authorize! @tripletex_integration
    end

    def create
      @tripletex_integration = @organization.tripletex_integration || @organization.build_tripletex_integration
      authorize! @tripletex_integration
      @tripletex_integration.employee_token = params.dig(:tripletex_integration, :employee_token).to_s.strip

      if @tripletex_integration.employee_token.blank?
        @tripletex_integration.errors.add(:employee_token, :blank)
        return render :new, status: :unprocessable_entity
      end

      company = @tripletex_integration.api.company
      @tripletex_integration.update!(company_id: company&.dig("id"), company_name: company&.dig("name"))
      redirect_to workspace_integrations_path, flash: { success: t("tripletex.integrations.connected", company: @tripletex_integration.company_name) }
    rescue Tripletex::Error => e
      @tripletex_integration.errors.add(:employee_token, e.message)
      render :new, status: :unprocessable_entity
    end

    def destroy
      @tripletex_integration = @organization.tripletex_integration
      return redirect_to workspace_integrations_path unless @tripletex_integration

      authorize! @tripletex_integration
      @tripletex_integration.destroy!
      redirect_to workspace_integrations_path, flash: { success: t("tripletex.integrations.disconnected") }
    end

    private

    def set_organization
      @organization = current_user.current_organization
    end

    def implicit_authorization_target
      TripletexIntegration
    end
  end
end
