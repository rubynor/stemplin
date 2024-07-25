class RemoveIsVerifiedFromUsers < ActiveRecord::Migration[7.0]
  def change
    safety_assured { remove_column :users, :is_verified, :boolean }
  end
end
