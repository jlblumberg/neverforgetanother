class ReminderMailer < ApplicationMailer
  def reminder_email(reminder)
    @reminder = reminder
    @user = reminder.user
    mail(
      to: @user.email,
      subject: "Reminder: #{@reminder.title}"
    )
  end
end
