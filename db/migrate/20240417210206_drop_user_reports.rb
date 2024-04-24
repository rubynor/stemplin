class DropUserReports < ActiveRecord::Migration[7.0]
  def change
    drop_table :user_reports
  end
end
