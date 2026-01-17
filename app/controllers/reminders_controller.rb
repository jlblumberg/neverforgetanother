class RemindersController < ApplicationController
  before_action :require_login
  before_action :set_reminder, only: [:show, :edit, :update, :cancel, :uncancel]

  def index
    @show_cancelled = params[:show_cancelled] == "true"
    @reminders = if @show_cancelled
      current_user.reminders.order(created_at: :desc)
    else
      current_user.reminders.active.order(created_at: :desc)
    end
  end

  def show
  end

  def new
    @reminder = current_user.reminders.build
  end

  def create
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
    redirect_to @reminder, notice: "Reminder cancelled successfully!"
  end

  def uncancel
    @reminder.update(cancelled: nil)
    redirect_to @reminder, notice: "Reminder reactivated successfully!"
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

    user_timezone = current_user.timezone || "UTC"
    # Parse the datetime string as if it's in the user's configured timezone, then convert to UTC
    # The datetime_local_field sends a string like "2026-01-20T14:30" which we interpret in user's timezone
    Time.use_zone(user_timezone) do
      parsed_time = Time.zone.parse(params[:reminder][:started])
      @reminder.started = parsed_time.utc if parsed_time
    end
  end
end
