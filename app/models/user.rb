class User < ApplicationRecord
  has_many :reminders, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :provider, presence: true
  validates :uid, presence: true
  validates :phone, phone: { countries: [:us], message: "must be a valid US phone number e.g. +1 (415) 555-1234" }, allow_blank: true
  validate :timezone_must_be_valid
  validates :uid, uniqueness: { scope: :provider }

  before_validation :normalize_phone

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.provider = auth.provider
      user.uid = auth.uid
      # timezone will be nil initially, detected on first page load
    end
  end

  private

  def normalize_phone
    return if phone.blank?

    raw = phone.to_s.strip
    return if raw.blank?

    parsed = Phonelib.parse(raw, "US")
    self.phone = parsed.valid? ? parsed.e164 : raw
  end

  def timezone_must_be_valid
    return if timezone.blank?

    unless ActiveSupport::TimeZone[timezone]
      errors.add(:timezone, "must be a valid IANA timezone (e.g., 'America/New_York')")
    end
  end
end
