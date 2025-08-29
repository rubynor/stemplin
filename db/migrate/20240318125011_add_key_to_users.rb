class AddKeyToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :key, :string
  end
end
