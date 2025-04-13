# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

# Sorcery to Devise Migration Guide

This document explains the technical implementation of migrating from the Sorcery authentication gem to Devise in a Rails application.

## Overview

The migration process was designed to be seamless, allowing users to continue using their existing credentials while gradually transitioning to Devise. The system supports both authentication methods simultaneously during the transition period.

## Technical Implementation

### Database Changes

1. Added new Devise-specific columns to the `users` table:
   - `encrypted_password`
   - `reset_password_token`
   - `reset_password_sent_at`
   - `remember_created_at`
   - `sign_in_count`
   - `current_sign_in_at`
   - `last_sign_in_at`
   - `current_sign_in_ip`
   - `last_sign_in_ip`

2. Added an `auth_system` column to track which authentication system is being used for each user:
   - `'sorcery'` for users still using Sorcery
   - `'devise'` for migrated users

### User Model Implementation

The `User` model was modified to support both authentication systems:

```ruby
class User < ApplicationRecord
  authenticates_with_sorcery!
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  attribute :auth_system, :string, default: 'sorcery'
end
```

### Password Migration Process

The migration process preserves user passwords by:

1. Storing the original Sorcery password hash and salt
2. Copying the Sorcery password hash directly to Devise's `encrypted_password` field
3. Updating the `auth_system` to 'devise'

The migration method in the User model:

```ruby
def migrate_to_devise!
  return if auth_system == 'devise'
  
  # Store the current Sorcery password hash and salt
  sorcery_password = self.crypted_password
  sorcery_salt = self.salt
  
  # Update the auth system
  self.auth_system = 'devise'
  
  # Set the encrypted password directly
  self.encrypted_password = sorcery_password
  
  # Save without validations
  save!(validate: false)
end
```

### Authentication Flow

The application controller and session controller handle both authentication systems:

1. When a user attempts to log in:
   - First checks if the user is using Sorcery
   - If yes, uses Sorcery's authentication
   - If no, uses Devise's authentication
   - Maintains session compatibility between both systems

2. The `current_user` method in `ApplicationController` handles both systems:
   ```ruby
   def current_user
     @current_user ||= begin
       if session[:user_id]
         User.find_by(id: session[:user_id])
       elsif respond_to?(:warden)
         warden.authenticate(scope: :user)
       end
     end
   end
   ```

### Migration Process

1. **Individual Migration**: Users can be migrated one at a time using:
   ```ruby
   user.migrate_to_devise!
   ```

2. **Batch Migration**: A Rake task is available for migrating users in batches:
   ```bash
   rake users:migrate_to_devise
   ```

### Test Specifications

The migration process is thoroughly tested with the following test suites:

#### 1. User Model Tests (`test/models/user_test.rb`)

```ruby
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
  
  # Test with wrong password
  assert_not user.valid_password?("wrong_password"), "Should not validate wrong password"
end
```

#### 2. Session Controller Tests (`test/controllers/user_sessions_controller_test.rb`)

```ruby
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
```

#### 3. Migration Rake Task Tests

The migration rake tasks are tested to ensure:
- Batch migration processes users correctly
- Individual user migration works as expected
- Error handling for failed migrations
- Progress reporting during batch migrations

#### 4. Integration Tests

Integration tests cover:
- Complete user flow from registration to login
- Password reset functionality
- Session management across both systems
- Cross-system authentication compatibility

#### 5. Security Tests

Security tests verify:
- Password hashing consistency
- Session security
- Protection against common authentication attacks
- Proper handling of authentication tokens

#### Running the Test Suite

To run the complete test suite:

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/user_test.rb

# Run specific test case
bin/rails test test/models/user_test.rb -n test_should_migrate_from_sorcery_to_devise
```

## Security Considerations

1. Password hashes are preserved during migration
2. No plaintext passwords are stored or transmitted
3. Both authentication systems use bcrypt for password hashing
4. Session handling is secure and consistent between systems

## Best Practices

1. Test the migration process thoroughly in a staging environment
2. Migrate users in small batches to monitor for issues
3. Keep both authentication systems active during the transition period
4. Monitor for any authentication failures during the migration
5. Have a rollback plan in case of issues

## Troubleshooting

If you encounter issues during migration:

1. Check the `auth_system` column value for the affected user
2. Verify the password hashes in both `crypted_password` and `encrypted_password` fields
3. Ensure the user's session is properly maintained during migration
4. Check the application logs for authentication-related errors

## Future Steps

1. Once all users are migrated, you can:
   - Remove Sorcery-specific code
   - Remove the `auth_system` column
   - Clean up any Sorcery-specific routes and controllers
   - Update the application to use only Devise authentication
