class SendReminderJob < ApplicationJob
  queue_as :default

  def perform(reminder_delivery_id)
    delivery = ReminderDelivery.find_by(id: reminder_delivery_id)
    return unless delivery

    # TODO: guards (already sent, reminder cancelled), send via channel, update row, retry logic
  end
end
