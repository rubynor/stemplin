class CreateOrganizations < ActiveRecord::Migration[7.0]
  def change
    create_table :organizations do |t|
      t.string :name

      t.timestamps
    end

    add_reference :clients, :organization
    add_reference :tasks, :organization
    add_reference :users, :organization
  end
end
