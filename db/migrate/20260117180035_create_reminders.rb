class CreateReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :reminders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, limit: 25, null: false
      t.string :description, limit: 100, null: false
      t.datetime :started, null: false
      t.integer :period, null: false
      t.boolean :email_enabled, default: false, null: false
      t.boolean :sms_enabled, default: false, null: false
      t.datetime :cancelled

      t.timestamps
    end
  end
end
