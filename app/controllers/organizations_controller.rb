class OrganizationsController < ApplicationController
  before_action :authenticate_user!

  def set_current_organization
    @organization = Organization.find(params[:id])
    authorize! @organization

    current_user.activate_organization!(@organization)

    redirect_back fallback_location: root_path
  end
end
