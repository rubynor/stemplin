class AddArchivedAtToAccessInfos < ActiveRecord::Migration[8.1]
  def change
    add_column :access_infos, :archived_at, :datetime
  end
end
