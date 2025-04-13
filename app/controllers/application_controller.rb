class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :require_login

  # Handle both Sorcery and Devise authentication
  def current_user
    @current_user ||= begin
      if session[:user_id]
        User.find_by(id: session[:user_id])
      elsif respond_to?(:warden)
        warden.authenticate(scope: :user)
      end
    end
  end
  helper_method :current_user

  private

  def require_login
    unless current_user
      redirect_to login_path, alert: "Please login first"
    end
  end

  def authenticate_user!
    unless current_user
      redirect_to login_path, alert: "Please login first"
    end
  end

  def not_authenticated
    redirect_to login_path, alert: "Please login first"
  end
end
