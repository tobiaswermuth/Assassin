class Game < ActiveRecord::Base
  include ExceptionHelper
  has_many :players, dependent: :destroy, autosave: true
  has_many :invitations, dependent: :destroy, autosave: true

  enum state: [ :join, :running, :over ]

  def self.new_def(name, rules, invitation_only)
    game = Game.new(
      :name => name,
      :rules => rules,
      :invitation_only => invitation_only,
      :password => SecureRandom.hex
    )
    game.save

    game
  end

  def create_invitation(user_name = nil)
    invitations.create(:name => user_name, :token => SecureRandom.hex)
  end

  def create_player(name, email, image_url)
    players.create(
      :name => name,
      :email => email,
      :image_url => image_url,
      :kill_pin => ('0'..'9').to_a.shuffle[0,4].join
    )
  end

  def player_by_id(player_id, fallback_url = "/")
    raise UserNotFoundException.new(player_id, fallback_url) if (player = players.where(:id => player_id).first).nil?
    player
  end

  def remaining_players
    players.where.not(:chaser => nil)
  end

  def dead_players
    players.where(:chaser => nil)
  end

  def winner
    if remaining_players.length == 1
      remaining_players.first
    end
  end
end
