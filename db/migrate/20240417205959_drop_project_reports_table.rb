class DropProjectReportsTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :project_reports
  end
end
