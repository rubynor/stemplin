class AddTripletexEmployeeIdToAccessInfos < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :access_infos, :tripletex_employee_id, :bigint, if_not_exists: true
    add_index :access_infos, [ :organization_id, :tripletex_employee_id ],
      unique: true, where: "tripletex_employee_id IS NOT NULL",
      name: "index_access_infos_on_organization_and_tripletex_employee",
      algorithm: :concurrently, if_not_exists: true
  end
end
