class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from CanCan::AccessDenied do |exception|
    render_file("#{Rails.root}/public/403.html", 403)
  end

  def catch_routing_error
    render_file("#{Rails.root}/public/404.html", 404)
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

  def redirect_to_home_page
    if logged_in?
      if current_user.has_role? 'dispatcher'
        redirect_to order_releases_path
      else
        redirect_to orders_delivery_path
      end
    else
      redirect_to login_path
    end
  end

  helper_method :logged_in?
  helper_method :current_user

  private
  def render_file(file, status)
    if logged_in?
      render :file => file, :status => status, :layout => false
    else
      redirect_to login_path
    end
  end

end
