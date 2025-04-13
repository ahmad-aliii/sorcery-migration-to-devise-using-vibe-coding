class UsersController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.auth_system = 'sorcery'  # Force using Sorcery for new users
    
    if @user.save
      auto_login(@user)
      redirect_to root_path, notice: 'Registration successful!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end 