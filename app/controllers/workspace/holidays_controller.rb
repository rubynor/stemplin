module Workspace
  class HolidaysController < WorkspaceController
    before_action :set_organization

    def show
      authorize! @organization
      @available_countries = Holidays.available_regions.sort
      @selected_country = @organization.holiday_country_code
    end

    def update
      authorize! @organization
      if @organization.update(organization_params)
        redirect_to workspace_holidays_path, notice: t("holidays.country_updated")
      else
        @available_countries = Holidays.available_regions.sort
        @selected_country = @organization.holiday_country_code
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_organization
      @organization = current_user.current_organization
    end

    def organization_params
      params.require(:organization).permit(:holiday_country_code)
    end

    def implicit_authorization_target
      Organization
    end
  end
end
