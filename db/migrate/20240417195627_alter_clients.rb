class AlterClients < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key :clients, :organizations
  end
end
