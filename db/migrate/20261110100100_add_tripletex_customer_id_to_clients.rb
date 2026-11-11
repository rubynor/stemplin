class AddTripletexCustomerIdToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :tripletex_customer_id, :bigint
  end
end
