class SettingsController < ApplicationController
  OTP_RESEND_THROTTLE_SECS = 30

  before_action :require_login

  def show
    set_phone_form_values_from_user
    @phone_country_code = "US"
    @show_otp_form = session[:pending_phone_verification].present?
    @pending_phone = session[:pending_phone_verification]&.dig("phone")
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

  def send_otp
    unless verify_profile_configured?
      send_otp_error("Verification is not configured. Please try again later.")
      return
    end

    pending = session[:pending_phone_verification]
    phone_in_params = params[:phone_number].to_s.strip.presence

    if phone_in_params.present?
      e164, country_iso, error = build_e164_from_params
      if error
        current_user.errors.add(:phone, error)
        set_phone_form_for_render
        render :show, status: :unprocessable_entity
        return
      end

      if User.where.not(id: current_user.id).where(phone: e164).exists?
        current_user.errors.add(:phone, "This number is already in use by another account.")
        set_phone_form_for_render
        render :show, status: :unprocessable_entity
        return
      end

      if current_user.phone_verified? && current_user.phone == e164
        redirect_to settings_path, notice: "This number is already verified for your account."
        return
      end

      if current_user.phone.present? && current_user.phone != e164 && !current_user.phone_change_allowed?
        current_user.errors.add(:phone, "You can only change your phone number once every #{User::PHONE_CHANGE_COOLDOWN_DAYS} days.")
        set_phone_form_for_render
        render :show, status: :unprocessable_entity
        return
      end

      if otp_send_throttled?
        send_otp_throttled_response(first_time: true)
        return
      end
      send_otp_to(e164, country_iso, first_time: true)
    elsif pending && pending["phone"].present?
      if current_user.phone_verified? && current_user.phone == pending["phone"]
        session.delete(:pending_phone_verification)
        session.delete(:otp_sent_at)
        redirect_to settings_path, notice: "This number is already verified for your account."
        return
      end
      if otp_send_throttled?
        send_otp_throttled_response(first_time: false)
        return
      end
      send_otp_to(pending["phone"], pending["country_iso"], first_time: false)
    else
      redirect_to settings_path, alert: "Please enter your phone number and request a code first."
    end
  end

  def verify_phone
    pending = session[:pending_phone_verification]
    unless pending && pending["phone"].present?
      redirect_to settings_path, alert: "Please enter your phone number and request a code first."
      return
    end

    code = params[:code].to_s.strip
    if code.blank?
      @show_otp_form = true
      @pending_phone = pending["phone"]
      set_phone_form_values_from_user
      flash.now[:alert] = "Please enter the verification code."
      render :show, status: :unprocessable_entity
      return
    end

    unless verify_profile_configured?
      redirect_to settings_path, alert: "Verification is not configured. Please try again later."
      return
    end

    begin
      response = telnyx_client.verifications.by_phone_number.actions.verify(
        pending["phone"],
        code: code,
        verify_profile_id: ENV["TELNYX_VERIFY_PROFILE_ID"]
      )
    rescue StandardError
      @show_otp_form = true
      @pending_phone = pending["phone"]
      set_phone_form_values_from_user
      flash.now[:alert] = "Couldn't verify. Try again."
      render :show, status: :unprocessable_entity
      return
    end

    if response.data.response_code == :accepted
      if User.where.not(id: current_user.id).where(phone: pending["phone"]).exists?
        session.delete(:pending_phone_verification)
        session.delete(:otp_sent_at)
        redirect_to settings_path, alert: "This number is already in use by another account."
        return
      end
      begin
        current_user.update!(
          phone: pending["phone"],
          phone_country_iso: pending["country_iso"],
          phone_verified_at: Time.current
        )
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        session.delete(:pending_phone_verification)
        session.delete(:otp_sent_at)
        redirect_to settings_path, alert: "This number is already in use by another account."
        return
      end
      session.delete(:pending_phone_verification)
      session.delete(:otp_sent_at)
      redirect_to settings_path, notice: "Phone number verified and saved."
    else
      @show_otp_form = true
      @pending_phone = pending["phone"]
      set_phone_form_values_from_user
      flash.now[:alert] = "Invalid or expired code. Try again or request a new code."
      render :show, status: :unprocessable_entity
    end
  end

  private

  def otp_send_throttled?
    sent_at = session[:otp_sent_at]
    return false unless sent_at
    sent_at = Time.zone.parse(sent_at.to_s) if sent_at.is_a?(String)
    (Time.current - sent_at) < OTP_RESEND_THROTTLE_SECS
  end

  def send_otp_throttled_response(first_time:)
    message = "Please wait #{OTP_RESEND_THROTTLE_SECS} seconds before requesting a new code."
    if first_time
      current_user.errors.add(:phone, message)
      set_phone_form_for_render
      render :show, status: :unprocessable_entity
    else
      redirect_to settings_path, alert: message
    end
  end

  def send_otp_error(message)
    current_user.errors.add(:phone, message)
    set_phone_form_for_render
    render :show, status: :unprocessable_entity
  end

  def send_otp_to(e164, country_iso, first_time:)
    begin
      telnyx_client.verifications.trigger_sms(
        phone_number: e164,
        verify_profile_id: ENV["TELNYX_VERIFY_PROFILE_ID"],
        timeout_secs: 300
      )
    rescue StandardError
      if first_time
        current_user.errors.add(:phone, "Couldn't send code. Try again.")
        set_phone_form_for_render
        render :show, status: :unprocessable_entity
      else
        redirect_to settings_path, alert: "Couldn't send code. Try again."
      end
      return
    end

    session[:pending_phone_verification] = { "phone" => e164, "country_iso" => country_iso }
    session[:otp_sent_at] = Time.current

    if first_time
      redirect_to settings_path, notice: "Verification code sent. Enter it below."
    else
      redirect_to settings_path, notice: "New code sent."
    end
  end

  def verify_profile_configured?
    ENV["TELNYX_VERIFY_PROFILE_ID"].present?
  end

  def telnyx_client
    @telnyx_client ||= Telnyx::Client.new(api_key: ENV["TELNYX_API_KEY"])
  end

  def build_e164_from_params
    country_iso = params[:phone_country_code].to_s.strip.upcase.presence
    phone_number = params[:phone_number].to_s.strip
    dial_code = country_iso && PhoneCountries.dial_code_for(country_iso)

    return [nil, nil, "Country and phone number are required."] if country_iso.blank? || phone_number.blank?
    return [nil, nil, "Please select a valid country."] if dial_code.blank?
    return [nil, nil, "Only US phone numbers are supported for text."] unless country_iso == "US"

    digits = phone_number.gsub(/\D/, "")
    digits = digits[dial_code.length..] if digits.start_with?(dial_code)
    full_phone = "+#{dial_code}#{digits}"

    parsed = Phonelib.parse(full_phone, "US")
    return [nil, nil, "must be a valid US phone number e.g. +1 (415) 555-1234"] unless parsed.valid?

    [parsed.e164, country_iso, nil]
  end

  def set_phone_form_for_render
    @phone_country_code = params[:phone_country_code].to_s.strip.presence
    @phone_number = params[:phone_number].to_s.strip.presence
    set_phone_form_values_from_user
  end

  def set_phone_form_values_from_user
    return if current_user.phone.blank?

    parsed = Phonelib.parse(current_user.phone)
    @phone_country_code = @phone_country_code.presence || current_user.phone_country_iso.presence || parsed.country
    @phone_number = @phone_number.presence || parsed.national_number
  end
end
