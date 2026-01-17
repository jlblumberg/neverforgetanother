class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :set_time_zone, if: -> { current_user&.timezone.present? }

  helper_method :current_user, :logged_in?

  private

  def set_time_zone(&block)
    Time.use_zone(current_user.timezone, &block)
  end

  def current_user
    return nil unless session[:user_id]
    
    @current_user ||= User.find_by(id: session[:user_id])
    # Clear invalid session if user no longer exists
    if @current_user.nil? && session[:user_id]
      session[:user_id] = nil
    end
    @current_user
  end

  def logged_in?
    !!current_user
  end

  def require_login
    unless logged_in?
      redirect_to root_path, alert: "You must be logged in to access this page."
    end
  end
end
