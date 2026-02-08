class SettingsController < ApplicationController
  before_action :require_login

  def show
    set_phone_form_values_from_user
  end

  def update_timezone
    timezone = params[:timezone]

    if timezone.present? && ActiveSupport::TimeZone[timezone]
      if current_user.update(timezone: timezone)
        respond_to do |format|
          format.json { head :ok }
          format.html { redirect_to settings_path, notice: "Timezone updated successfully!" }
        end
      else
        respond_to do |format|
          format.json { head :unprocessable_entity }
          format.html { redirect_to settings_path, alert: "Failed to update timezone." }
        end
      end
    else
      respond_to do |format|
        format.json { head :unprocessable_entity }
        format.html { redirect_to settings_path, alert: "Invalid timezone." }
      end
    end
  end

  def update_phone
    country_iso = params[:phone_country_code].to_s.strip.upcase.presence
    phone_number = params[:phone_number].to_s.strip
    dial_code = country_iso && PhoneCountries.dial_code_for(country_iso)

    if country_iso.blank? || phone_number.blank?
      current_user.errors.add(:phone, "Country and phone number are required.")
      @phone_country_code = params[:phone_country_code].to_s.strip.presence
      @phone_number = params[:phone_number].to_s.strip.presence
      render :show, status: :unprocessable_entity
      return
    end

    if dial_code.blank?
      current_user.errors.add(:phone, "Please select a valid country.")
      @phone_country_code = country_iso
      @phone_number = phone_number
      render :show, status: :unprocessable_entity
      return
    end

    unless country_iso == "US"
      current_user.errors.add(:phone, "Only US phone numbers are supported for SMS.")
      @phone_country_code = country_iso
      @phone_number = phone_number
      render :show, status: :unprocessable_entity
      return
    end

    digits = phone_number.gsub(/\D/, "")
    digits = digits[dial_code.length..] if digits.start_with?(dial_code)
    full_phone = "+#{dial_code}#{digits}"

    if current_user.update(phone: full_phone, phone_country_iso: country_iso)
      respond_to do |format|
        format.json { head :ok }
        format.html { redirect_to settings_path, notice: "Phone number updated." }
      end
    else
      @phone_country_code = country_iso
      @phone_number = params[:phone_number].to_s.strip.presence
      set_phone_form_values_from_user
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_phone_form_values_from_user
    return if current_user.phone.blank?

    parsed = Phonelib.parse(current_user.phone)
    # Prefer stored selection; fall back to Phonelib when blank. US-only for SMS.
    @phone_country_code = @phone_country_code.presence || current_user.phone_country_iso.presence || parsed.country
    @phone_number = @phone_number.presence || parsed.national_number
  end
end
