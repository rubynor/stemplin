class AddIsVerifiedToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :is_verified, :boolean, default: true
  end
end
