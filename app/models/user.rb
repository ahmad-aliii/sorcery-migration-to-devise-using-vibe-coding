class User < ApplicationRecord
  authenticates_with_sorcery!
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  # Add a column to track which authentication system is being used
  attribute :auth_system, :string, default: 'sorcery'

  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 6 }, if: -> { new_record? || password.present? }
  validates :password, confirmation: true, if: -> { new_record? || password.present? }
  validates :password_confirmation, presence: true, if: -> { new_record? || password.present? }

  # Override Devise's password getter to work with both systems
  def password
    if auth_system == 'sorcery'
      @password ||= super
    else
      @password ||= Devise.friendly_token[0, 20]
    end
  end

  # Override Devise's password setter to work with both systems
  def password=(new_password)
    if auth_system == 'sorcery'
      super
    else
      @password = new_password
      self.encrypted_password = Devise::Encryptor.digest(self.class, new_password) if new_password.present?
    end
  end

  # Method to migrate a user from Sorcery to Devise
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

  # Override Devise's valid_password? method to handle both authentication systems
  def valid_password?(password)
    if auth_system == 'sorcery'
      valid_sorcery_password?(password)
    else
      # For Devise, we need to verify using the original Sorcery method
      # since we copied the Sorcery hash directly
      crypto_provider = Sorcery::CryptoProviders::BCrypt
      crypto_provider.matches?(self.encrypted_password, password, self.salt)
    end
  end

  # Add authenticate method for Sorcery compatibility
  def authenticate(password)
    if valid_password?(password)
      self
    else
      false
    end
  end

  private

  def valid_sorcery_password?(password)
    crypto_provider = Sorcery::CryptoProviders::BCrypt
    crypto_provider.matches?(self.crypted_password, password, self.salt)
  end
end 