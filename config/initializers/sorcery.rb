# Configure Sorcery core
Rails.application.config.sorcery.configure do |config|
  config.user_config do |user|
    user.username_attribute_names = [:email]
    user.password_attribute_name = :password
    user.downcase_username_before_authenticating = true
    user.email_attribute_name = :email
    user.crypted_password_attribute_name = :crypted_password
    user.salt_attribute_name = :salt
    user.encryption_algorithm = :bcrypt
    user.stretches = 1 if Rails.env.test?
  end

  config.user_class = "User"
end
