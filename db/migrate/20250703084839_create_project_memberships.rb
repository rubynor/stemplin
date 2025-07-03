class CreateProjectMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :project_memberships do |t|
      t.references :project, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.integer :rate, default: 0
      t.boolean :billable
      t.integer :role, null: false, default: 0
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :project_memberships, [:project_id, :organization_id], unique: true, where: "discarded_at IS NULL"
    add_index :project_memberships, :discarded_at

    billing_info = Project.joins(:client).pluck(:id, "clients.organization_id", :rate, :billable).each_with_object([]) do |item, array|
      array << {project_id: item[0], organization_id: item[1], rate: item[2], billable: item[3], role: :owner}
    end
    ProjectMembership.insert_all!(billing_info)
  end
end
