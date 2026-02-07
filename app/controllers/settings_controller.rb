class SettingsController < ApplicationController
  before_action :require_login

  def show
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
    if current_user.update(phone: params[:phone].to_s.strip.presence)
      respond_to do |format|
        format.json { head :ok }
        format.html { redirect_to settings_path, notice: "Phone number updated." }
      end
    else
      respond_to do |format|
        format.json { head :unprocessable_entity }
        format.html { redirect_to settings_path, alert: current_user.errors.full_messages.to_sentence }
      end
    end
  end
end
