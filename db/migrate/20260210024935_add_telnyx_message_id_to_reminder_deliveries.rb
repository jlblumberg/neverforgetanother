class AddTelnyxMessageIdToReminderDeliveries < ActiveRecord::Migration[8.1]
  def change
    add_column :reminder_deliveries, :telnyx_message_id, :string
  end
end
