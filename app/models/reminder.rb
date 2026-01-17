class Reminder < ApplicationRecord
  belongs_to :user

  enum :period, {
    one_off: 0,
    daily: 1,
    weekly: 2,
    monthly: 3,
    quarterly: 4,
    yearly: 5
  }

  validates :title, presence: true, length: { maximum: 25 }
  validates :description, presence: true, length: { maximum: 100 }
  validates :started, presence: true
  validates :period, presence: true
  validate :started_must_be_in_future
  validate :at_least_one_delivery_method

  scope :active, -> { where(cancelled: nil) }
  scope :cancelled, -> { where.not(cancelled: nil) }

  def active?
    cancelled.nil?
  end

  def cancel!
    update(cancelled: Time.current)
  end

  # Calculate the next time this reminder should be sent
  # Returns nil if reminder is cancelled or if it's a one-off that's already been sent
  # Note: This will work fully once ReminderDelivery model is created in Phase 5
  def next_send_time
    return nil unless active?

    # Check if ReminderDelivery association exists (will be created in Phase 5)
    if respond_to?(:reminder_deliveries)
      last_delivery = reminder_deliveries.order(sent: :desc).first

      if last_delivery.nil?
        # No deliveries yet, use the started time
        started
      elsif one_off?
        # One-off reminders only send once
        nil
      else
        # Recurring reminders: calculate from last delivery + period
        last_delivery.sent + period_duration
      end
    else
      # ReminderDelivery model doesn't exist yet, just use started time
      started
    end
  end

  # Check if this reminder is due to be sent now
  def due?
    return false unless active?

    if respond_to?(:reminder_deliveries)
      return false if one_off? && reminder_deliveries.exists?
    end

    next_time = next_send_time
    return false if next_time.nil?

    next_time <= Time.current
  end

  def delivery_methods
    methods = []
    methods << :email if email_enabled?
    methods << :sms if sms_enabled?
    methods
  end

  def delivery_methods_humanized
    delivery_methods.map(&:to_s).map(&:humanize).join(", ")
  end

  private

  def started_must_be_in_future
    return unless started.present?

    if started <= Time.current
      errors.add(:started, "must be in the future")
    end
  end

  def at_least_one_delivery_method
    unless email_enabled? || sms_enabled?
      errors.add(:base, "At least one delivery method must be selected")
    end
  end

  def period_duration
    case period
    when "daily"
      1.day
    when "weekly"
      1.week
    when "monthly"
      1.month
    when "quarterly"
      3.months
    when "yearly"
      1.year
    else
      0
    end
  end
end
