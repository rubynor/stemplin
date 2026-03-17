class AddCurrencyToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :currency, :string

    reversible do |dir|
      dir.up do
        Organization.update_all(currency: "NOK")
      end
    end
  end
end
