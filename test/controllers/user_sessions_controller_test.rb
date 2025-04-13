require 'test_helper'

class UserSessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  setup do
    @password = "password123"
    @user = User.create!(
      email: "test@example.com",
      password: @password,
      password_confirmation: @password,
      auth_system: 'sorcery'
    )
  end

  test "should login with sorcery authentication" do
    post login_path, params: { email: @user.email, password: @password }
    assert_redirected_to root_path
    assert_equal "Login successful", flash[:notice]
  end

  test "should login with devise authentication after migration" do
    @user.migrate_to_devise!
    @user.reload
    post login_path, params: { email: @user.email, password: @password }
    assert_redirected_to root_path
    assert_equal "Login successful", flash[:notice]
  end

  test "should not login with invalid credentials" do
    post login_path, params: { email: @user.email, password: "wrong_password" }
    assert_response :unprocessable_entity
    assert_equal "Login failed", flash[:alert]
  end

  test "should logout" do
    post login_path, params: { email: @user.email, password: @password }
    assert_redirected_to root_path
    delete logout_path
    assert_redirected_to root_path
    assert_equal "Logged out!", flash[:notice]
  end
end 