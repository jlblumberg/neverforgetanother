class ScheduleRemindersJob < ApplicationJob
  queue_as :default

  def perform
    Reminder.active.includes(:reminder_deliveries).find_each do |reminder|
      next unless reminder.due?

      # due? guarantees next_send_time is present and <= now
      scheduled_at = reminder.next_send_time

      reminder.delivery_methods.each do |channel|
        create_and_enqueue_delivery(reminder, channel, scheduled_at)
      end
    end
  end

  private

  def create_and_enqueue_delivery(reminder, channel, scheduled_at)
    return if reminder.reminder_deliveries.exists?(scheduled_at: scheduled_at, channel: channel)

    delivery = reminder.reminder_deliveries.build(
      channel: channel,
      scheduled_at: scheduled_at,
      status: :pending,
      attempt_count: 0
    )
    delivery.save!
    SendReminderJob.perform_later(delivery.id)
  rescue ActiveRecord::RecordNotUnique
    # Another scheduler run or worker created it; skip
  end
end
