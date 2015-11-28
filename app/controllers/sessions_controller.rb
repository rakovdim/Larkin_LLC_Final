class SessionsController < ApplicationController

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

  private
  def get_login
    params[:session][:login].downcase
  end

  def get_password
    params[:session][:password]
  end



end
