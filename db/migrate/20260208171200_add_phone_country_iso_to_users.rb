class AddPhoneCountryIsoToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :phone_country_iso, :string
  end
end
