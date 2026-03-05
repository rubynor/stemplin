class AddRegistrationIpToOauthApplications < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :oauth_applications, :registration_ip, :inet
    add_index :oauth_applications, :registration_ip, algorithm: :concurrently
  end
end
