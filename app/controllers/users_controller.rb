class UsersController < ApplicationController
  #before_filter :load_user_service

  # def list
  #   @users = @user_service.get_all_users
  #   # @users=[]
  # end
  #
  # def load_user_service(service = UserService.new)
  #   @user_service ||= service
  # end
  #
  # def show
  #   @user=User.find(params[:id])
  #   #debugger
  # end
  #
  # def name
  #   @user = User.find_by_login (params[:login])
  #   redirect_to @user
  # end
  #
  # def new
  #   @user = User.new
  # end
  #
  # def create
  #   @user = User.new(user_params)
  #   if @user.save
  #     redirect_to @user
  #   else
  #     render 'new'
  #   end
  # end
  #
  # private def user_params
  #   params.require(:user).permit(:login, :password,
  #                                :password_confirmation)
  # end
end
