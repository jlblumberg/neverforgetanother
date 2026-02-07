# At-least-once delivery: we may send twice if we succeed but fail to persist "sent".
# We never persist "sent" unless we actually sent; so we never lose a reminder.
class SendReminderJob < ApplicationJob
  queue_as :default

  MAX_ATTEMPTS = 3

  def perform(reminder_delivery_id)
    delivery = nil
    delivery = ReminderDelivery.find_by(id: reminder_delivery_id)
    return unless delivery

    reminder = delivery.reminder

    # Idempotent: already sent (by status or sent_at) or permanently failed, do nothing
    return if delivery.sent? || delivery.failed? || delivery.sent_at.present?

    # Reminder was cancelled after this delivery was enqueued
    unless reminder.active?
      delivery.update_columns(status: ReminderDelivery.statuses[:failed], error_message: "Reminder was cancelled")
      return
    end

    delivery.increment!(:attempt_count)

    send_via_channel(delivery)
    delivery.update_columns(sent_at: Time.current, status: ReminderDelivery.statuses[:sent])
  rescue StandardError => e
    if delivery
      delivery.update_columns(error_message: e.message)
      if delivery.attempt_count >= MAX_ATTEMPTS
        delivery.update_column(:status, ReminderDelivery.statuses[:failed])
      else
        raise
      end
    else
      raise
    end
  end

  private

  def send_via_channel(delivery)
    if delivery.email?
      ReminderMailer.reminder_email(delivery.reminder).deliver_now
    elsif delivery.sms?
      # Configure Twilio (or another provider) and replace this with the actual send.
      raise "SMS delivery not configured. Add a provider (e.g. Twilio) in SendReminderJob#send_via_channel."
    end
  end
end
