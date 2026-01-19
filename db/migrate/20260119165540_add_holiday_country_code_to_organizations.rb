class AddHolidayCountryCodeToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :holiday_country_code, :string
  end
end
