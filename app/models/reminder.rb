class Reminder < ApplicationRecord
  belongs_to :user
  has_many :reminder_deliveries, dependent: :destroy

  # Text: 160 chars total; body = prefix + title + separator + description
  SMS_PREFIX = "Reminder from neverforgetanother.com: "
  SMS_SEPARATOR = " - "
  SMS_MAX_LENGTH = 160
  SMS_BODY_MAX = SMS_MAX_LENGTH - SMS_PREFIX.length - SMS_SEPARATOR.length # 121

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
  validate :sms_body_fits_when_sms_enabled, if: :sms_enabled?
  validate :user_has_phone_when_sms_enabled, if: :sms_enabled?

  scope :active, -> { where(cancelled: nil) }
  scope :cancelled, -> { where.not(cancelled: nil) }

  def active?
    cancelled.nil?
  end

  def completed?
    return false unless active?
    return false unless one_off?

    # One-off is completed only when every configured channel has at least one sent delivery
    delivery_methods.all? { |channel| reminder_deliveries.sent.where(channel: channel).exists? }
  end

  def cancel!
    update(cancelled: Time.current)
  end

  # Calculate the next time this reminder should be sent.
  # One-off: returns started until completed? (all channels sent), then nil — keeps reminder due so scheduler can create/enqueue missing channel deliveries.
  # Recurring: anchors on scheduled_at (not sent_at) so late sends don't slide the schedule.
  def next_send_time
    return nil unless active?

    last_delivery = reminder_deliveries.order(scheduled_at: :desc).first

    if last_delivery.nil?
      started
    elsif one_off?
      completed? ? nil : started
    else
      last_delivery.scheduled_at + period_duration
    end
  end

  # Check if this reminder is due to be sent now.
  # Derived from next_send_time only (which is nil for one-off once any delivery exists), so no gap vs completed?
  def due?
    return false unless active?

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

  def sms_body_fits_when_sms_enabled
    return unless title && description
    total = title.length + description.length
    return if total <= SMS_BODY_MAX
    errors.add(:base, "Title and description together must be #{SMS_BODY_MAX} characters or less for text (currently #{total})")
  end

  def user_has_phone_when_sms_enabled
    return if user&.phone.present?
    errors.add(:base, "Phone number is required for text reminders. Add one in Settings.")
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
