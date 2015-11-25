class UserService

  def login (login, password)
    user = User.find_by_login(login)

    user if user && user.authenticate(password)
  end
end