class CreateProjectReports < ActiveRecord::Migration[7.0]
  def change
    create_table :project_reports do |t|
      t.string :creator
      t.string :timeframe
      t.date :date_start
      t.date :date_end
      t.string :client_id
      t.string :project_id
      t.text :task_ids, array: true, default: []
      t.text :member_ids, array: true, default: []
      t.string :group_by

      t.timestamps
    end
  end
end
