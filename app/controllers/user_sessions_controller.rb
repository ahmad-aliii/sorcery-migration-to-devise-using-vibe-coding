class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
    @user = User.new
  end

  def create
    authenticated = false
    @user = nil
    
    # Try Sorcery authentication first
    if User.find_by(email: params[:email])&.auth_system == 'sorcery'
      @user = login(params[:email], params[:password])
      authenticated = !@user.nil?
    else
      # Try Devise authentication
      @user = User.find_by(email: params[:email])
      if @user&.valid_password?(params[:password])
        sign_in(@user)
        session[:user_id] = @user.id # Set session for compatibility
        authenticated = true
      end
    end

    if authenticated
      redirect_back_or_to root_path, notice: 'Login successful'
    else
      @user = User.new
      flash.now[:alert] = 'Login failed'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    # Try both logout methods
    if current_user
      session[:user_id] = nil
      logout if respond_to?(:logout)
      sign_out(current_user) if respond_to?(:sign_out)
    end
    redirect_to root_path, notice: 'Logged out!'
  end
end 