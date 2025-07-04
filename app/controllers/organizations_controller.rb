class OrganizationsController < ApplicationController
  def set_current_organization
    @organization = Organization.find(params[:id])
    authorize! @organization

    ActiveRecord::Base.transaction do
      access_infos = current_user.access_infos
      active_access_info = current_user.access_info

      active_access_info.update(active: false)
      access_infos.find_by(organization: @organization).update(active: true)
    end

    redirect_back fallback_location: root_path
  end
end
