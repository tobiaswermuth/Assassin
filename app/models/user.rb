class User
  attr_accessor :id, :name, :email, :image_url, :target, :killer, :kill_pin

  def initialize(name, email, image_url)
    @id = SecureRandom.hex
    @name = name
    @email = email
    @image_url = image_url
    @kill_pin = ('0'..'9').to_a.shuffle[0,4].join
  end

  def is_alive?
    !@target.nil?
  end
end
