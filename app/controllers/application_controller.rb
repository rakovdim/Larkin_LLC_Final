class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from CanCan::AccessDenied do |exception|
    if logged_in?
      render :file => "#{Rails.root}/public/403.html", :status => 403, :layout => false
    else
      redirect_to login_path
    end
  end

  def current_user
    return unless session[:user_id]
    @current_user ||= User.find(session[:user_id])
  end

  def clear_current_user
    @current_user=nil
  end

  def logged_in?
    !current_user.nil?
  end

  helper_method :logged_in?
  helper_method :current_user

end
