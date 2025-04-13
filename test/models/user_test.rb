require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "should migrate from sorcery to devise and maintain password" do
    # Create a user with Sorcery
    password = "password123"
    user = User.create!(
      email: "test@example.com",
      password: password,
      password_confirmation: password,
      auth_system: 'sorcery'
    )
    
    # Verify user was created with Sorcery
    assert_equal 'sorcery', user.auth_system
    assert user.authenticate(password), "Should authenticate with Sorcery"
    
    # Migrate to Devise
    user.migrate_to_devise!
    
    # Reload user to get fresh state
    user.reload
    
    # Verify migration
    assert_equal 'devise', user.auth_system
    
    # Test Devise authentication
    assert user.valid_password?(password), "Should authenticate with Devise after migration"
    
    # Test Devise's valid_password? method directly
    assert user.valid_password?(password), "Should validate password with Devise"
    
    # Test with wrong password
    assert_not user.valid_password?("wrong_password"), "Should not validate wrong password"
  end
end 