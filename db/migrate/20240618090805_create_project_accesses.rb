class CreateProjectAccesses < ActiveRecord::Migration[7.0]
  def change
    create_table :project_accesses do |t|
      t.references :project, null: false, foreign_key: true
      t.references :access_info, null: false, foreign_key: true

      t.timestamps
    end

    reversible do |dir|
      dir.up do
        # Create project accesses for all organization users when migrating
        ProjectAccess.transaction do
          AccessInfo.where(role: AccessInfo.roles[:organization_user]).find_each(batch_size: 1000) do |access_info|
            access_info.organization.projects.find_each(batch_size: 1000) do |project|
              ProjectAccess.create!(project: project, access_info: access_info)
            end
          end
        end
      end
    end
  end
end
