class User < ApplicationRecord
  has_many :reminders, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :provider, presence: true
  validates :uid, presence: true
  validates :phone, format: { with: /\A\+?[1-9]\d{1,14}\z/, message: "must be in E.164 format" }, allow_blank: true
  validate :timezone_must_be_valid
  validates :uid, uniqueness: { scope: :provider }

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.provider = auth.provider
      user.uid = auth.uid
      # timezone will be nil initially, detected on first page load
    end
  end

  private

  def timezone_must_be_valid
    return if timezone.blank?

    unless ActiveSupport::TimeZone[timezone]
      errors.add(:timezone, "must be a valid IANA timezone (e.g., 'America/New_York')")
    end
  end
end
