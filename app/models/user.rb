class User
  attr_accessor :id, :name, :email, :image_url, :game, :target

  def initialize(name, email, image_url, game)
    @id = SecureRandom.hex
    @name = name
    @email = email
    @image_url = image_url
    @game = game
  end
end
