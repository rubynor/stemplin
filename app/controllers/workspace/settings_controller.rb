module Workspace
  class SettingsController < WorkspaceController
    before_action :set_organization

    def show
      authorize! @organization
    end

    def edit
      authorize! @organization
      @available_currencies = Stemplin.config.currencies.keys
    end

    def update
      authorize! @organization
      if @organization.update(organization_params)
        redirect_to workspace_settings_path
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_organization
      @organization = current_user.current_organization
    end

    def organization_params
      params.require(:organization).permit(:currency, :advanced_time_copying)
    end

    def implicit_authorization_target
      Organization
    end
  end
end
