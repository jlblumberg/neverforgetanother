class AddPhoneVerifiedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :phone_verified_at, :datetime unless column_exists?(:users, :phone_verified_at)
    unless index_exists?(:users, :phone, name: "index_users_on_phone")
      add_index :users, :phone, unique: true, where: "phone IS NOT NULL"
    end
  end
end
