class HomeController < ApplicationController
  def index
    redirect_to reminders_path if logged_in?
  end
end
