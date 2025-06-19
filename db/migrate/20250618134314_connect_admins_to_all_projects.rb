class ConnectAdminsToAllProjects < ActiveRecord::Migration[7.1]
  def up
    # Create project accesses between all organization admins and projects within the same organization
    # This ensures admins have access to all projects when the project restriction feature is enabled
    ProjectAccess.transaction do
      AccessInfo.where(role: AccessInfo.roles[:organization_admin]).find_each(batch_size: 1000) do |access_info|
        access_info.organization.projects.find_each(batch_size: 1000) do |project|
          ProjectAccess.create!(project: project, access_info: access_info) unless ProjectAccess.exists?(project: project, access_info: access_info)
        end
      end
    end
  end

  def down
    # Remove project accesses for organization admins
    ProjectAccess.joins(:access_info).where(access_infos: { role: AccessInfo.roles[:organization_admin] }).delete_all
  end
end
