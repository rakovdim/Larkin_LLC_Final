class User < ActiveRecord::Base
  has_secure_password
  validates :login, presence: true

  def has_role? (role)
    role == user_role
  end

end
