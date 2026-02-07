class CreateReminderDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :reminder_deliveries do |t|
      t.references :reminder, null: false, foreign_key: true
      t.integer :channel, null: false
      t.datetime :scheduled_at, null: false
      t.datetime :sent_at
      t.integer :status, null: false, default: 0
      t.text :error_message
      t.integer :attempt_count, null: false, default: 0

      t.timestamps
    end

    add_index :reminder_deliveries, %i[reminder_id scheduled_at channel], unique: true, name: "index_reminder_deliveries_on_reminder_scheduled_at_channel"
  end
end
