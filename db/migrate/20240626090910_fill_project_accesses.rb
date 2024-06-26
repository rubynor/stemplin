class FillProjectAccesses < ActiveRecord::Migration[7.0]
  def up
    # Create project accesses between all users and projects within the same organization
    # This way, users will have access to all projects within their organization, just like before the project access feature was introduced
    ProjectAccess.transaction do
      AccessInfo.where(role: AccessInfo.roles[:organization_user]).find_each(batch_size: 1000) do |access_info|
        access_info.organization.projects.find_each(batch_size: 1000) do |project|
          ProjectAccess.create!(project: project, access_info: access_info)
        end
      end
    end
  end

  def down
    ProjectAccess.destroy_all
  end
end
