class AddActiveToAccessInfos < ActiveRecord::Migration[7.0]
  def change
    add_column :access_infos, :active, :boolean, default: false
  end
end
