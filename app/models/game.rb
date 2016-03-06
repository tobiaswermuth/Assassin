class Game
  attr_accessor :id, :name, :rules, :users, :password, :state

  def initialize(name, rules)
    @id = SecureRandom.hex
    @name = name
    @rules = rules
    @password = SecureRandom.hex
    @users = {}
    @state = :join
  end

  def user_by_id(user_id, fallback_url = "/")
    raise UserNotFoundException.new(user_id, fallback_url) if (user = @users[user_id]).nil?
    user
  end

  def remaining_users
    @users.values.select do |user|
      !user.target.nil?
    end
  end

  def winner
    if remaining_users.length == 1
      remaining_users.first
    end
  end
end
