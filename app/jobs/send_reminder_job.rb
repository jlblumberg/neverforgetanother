class SendReminderJob < ApplicationJob
  queue_as :default

  MAX_ATTEMPTS = 3

  def perform(reminder_delivery_id)
    delivery = ReminderDelivery.find_by(id: reminder_delivery_id)
    return unless delivery

    reminder = delivery.reminder

    # Idempotent: already sent, do nothing
    return if delivery.sent?

    # Reminder was cancelled after this delivery was enqueued
    unless reminder.active?
      delivery.update_columns(status: ReminderDelivery.statuses[:failed], error_message: "Reminder was cancelled")
      return
    end

    delivery.increment!(:attempt_count)

    send_via_channel(delivery)
    delivery.update_columns(sent_at: Time.current, status: ReminderDelivery.statuses[:sent])
  rescue StandardError => e
    delivery.update_columns(error_message: e.message)
    if delivery.attempt_count >= MAX_ATTEMPTS
      delivery.update_column(:status, ReminderDelivery.statuses[:failed])
      # Don't re-raise: stop retrying
    else
      raise
    end
  end

  private

  # Placeholder: no external sender configured. Replace with ReminderMailer / Twilio when ready.
  def send_via_channel(delivery)
    # no-op
  end
end
