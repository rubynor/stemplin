class RemoveOrganizationIdAndKeyToUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :organization_id
    remove_column :users, :key
  end
end
