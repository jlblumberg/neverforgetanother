class RemindersController < ApplicationController
  before_action :require_login
  before_action :set_reminder, only: [:show, :edit, :update, :cancel, :uncancel]

  def index
    all_active = current_user.reminders.active.order(created_at: :desc).to_a
    @active_reminders = all_active.reject(&:completed?)
    completed_reminders = all_active.select(&:completed?)
    cancelled_reminders = current_user.reminders.cancelled.order(created_at: :desc).to_a
    @archived_reminders = (completed_reminders + cancelled_reminders).sort_by(&:created_at).reverse
  end

  def show
  end

  def new
    @reminder = current_user.reminders.build
  end

  def create
    unless current_user.timezone.present?
      redirect_to settings_path, alert: "Please set your timezone before creating reminders."
      return
    end

    @reminder = current_user.reminders.build(reminder_params)
    
    # Convert user's local timezone to UTC for storage
    convert_started_time_to_utc

    if @reminder.save
      redirect_to @reminder, notice: "Reminder created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    unless current_user.timezone.present?
      redirect_to settings_path, alert: "Please set your timezone before updating reminders."
      return
    end

    # Convert user's local timezone to UTC for storage
    convert_started_time_to_utc

    if @reminder.update(reminder_params)
      redirect_to @reminder, notice: "Reminder updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def cancel
    @reminder.cancel!
    redirect_back(fallback_location: reminders_path, notice: "Reminder cancelled successfully!")
  end

  def uncancel
    @reminder.update(cancelled: nil)
    redirect_back(fallback_location: reminders_path, notice: "Reminder reactivated successfully!")
  end

  private

  def set_reminder
    @reminder = current_user.reminders.find(params[:id])
  end

  def reminder_params
    params.require(:reminder).permit(:title, :description, :started, :period, :email_enabled, :sms_enabled)
  end

  def convert_started_time_to_utc
    return unless params[:reminder][:started].present?

    # Parse the datetime string in the user's timezone, then convert to UTC
    # The datetime_local_field sends a string like "2026-01-20T14:30" which we interpret in user's timezone
    parsed_time = Time.use_zone(current_user.timezone) { Time.zone.parse(params[:reminder][:started]) }
    @reminder.started = parsed_time.utc if parsed_time
  end
end
