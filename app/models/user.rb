class User
  attr_accessor :id, :name, :email, :image_url, :game, :target, :kill_pin

  def initialize(name, email, image_url, game)
    @id = SecureRandom.hex
    @name = name
    @email = email
    @image_url = image_url
    @game = game
    @kill_pin = ('0'..'9').to_a.shuffle[0,4].join
  end
end
