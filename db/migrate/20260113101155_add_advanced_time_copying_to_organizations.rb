class AddAdvancedTimeCopyingToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :advanced_time_copying, :boolean, default: false, null: false
  end
end
