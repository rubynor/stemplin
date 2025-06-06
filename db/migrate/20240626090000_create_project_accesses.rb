class CreateProjectAccesses < ActiveRecord::Migration[7.0]
  def change
    create_table :project_accesses do |t|
      t.references :project, null: false, foreign_key: true
      t.references :access_info, null: false, foreign_key: true

      t.index [ :project_id, :access_info_id ], unique: true

      t.timestamps
    end
  end
end
