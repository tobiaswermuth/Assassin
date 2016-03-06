class Game
  include RedirectionHelper
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
    redirect_if((user = @users[user_id]).nil?, fallback_url)
    user
  end
end
