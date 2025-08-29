class AlterUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :role
  end
end
