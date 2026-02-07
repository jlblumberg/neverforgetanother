class ReminderDelivery < ApplicationRecord
  belongs_to :reminder

  enum :channel, { email: 0, sms: 1 }
  enum :status, { pending: 0, sent: 1, failed: 2 }

  validates :channel, presence: true
  validates :scheduled_at, presence: true
  validates :status, presence: true
  validates :attempt_count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
