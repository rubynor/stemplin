class AddPayrollSettingsToTripletexIntegrations < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_column :tripletex_integrations, :hourly_salary_type_id, :bigint, if_not_exists: true
    add_column :tripletex_integrations, :connected_at, :datetime, if_not_exists: true

    safety_assured { execute "UPDATE tripletex_integrations SET connected_at = created_at WHERE connected_at IS NULL" }

    add_check_constraint :tripletex_integrations, "connected_at IS NOT NULL", name: "tripletex_integrations_connected_at_null", validate: false
    validate_check_constraint :tripletex_integrations, name: "tripletex_integrations_connected_at_null"
    change_column_null :tripletex_integrations, :connected_at, false
    remove_check_constraint :tripletex_integrations, name: "tripletex_integrations_connected_at_null"
  end

  def down
    remove_column :tripletex_integrations, :connected_at, if_exists: true
    remove_column :tripletex_integrations, :hourly_salary_type_id, if_exists: true
  end
end
