class SessionsController < ApplicationController

  #todo go to home_page
  def new

  end

  def home
    redirect_to_home_page
  end

  def create
    user = User.find_by_login(get_login)
    if user && user.authenticate(get_password)
      session[:user_id] = user.id
      redirect_to_home_page
    else
      flash.now[:danger] = 'Invalid login/password combination'
      render 'new'
    end
  end

  def destroy
    log_out
    redirect_to root_url
  end

  def log_out
    session.delete(:user_id)
    clear_current_user
  end

  private def get_login
    params[:session][:login].downcase
  end

  private def get_password
    params[:session][:password]
  end

  private def redirect_to_home_page
    if logged_in?
      if current_user.has_role? 'dispatcher'
        redirect_to order_releases_path
      else
        redirect_to loads_delivery_path
      end
    else
      redirect_to login_path
    end
  end

end
