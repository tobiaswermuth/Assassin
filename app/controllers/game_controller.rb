class GameController < ActionController::Base
  include ExceptionHelper

  layout "application"
  protect_from_forgery with: :null_session

  rescue_from RedirectionException, :with => :redirect_exception

  @@titles = {
    "create" => "Create a new Assassin Game",
    "join_get_id" => "Join an Assassin Game"
  }

  before_action {
    @title = @@titles[action_name]
  }

  @@min_players = 2


  def do_create
    game = Game.new_def params[:name], params[:rules], !params[:invitation_only].nil?

    redirect_to game_admin_route game, "overview"
  end

  def overview
    @game = game_by_id params[:id], "/"
    check_admin_password @game, params[:password]

    @title = "#{@game.name} - Administration"
    states = {
        "join" => {
          :title => "Join",
          :description => "Players are able to join the Assassin Game.",
          :button_replacement_type => "warning",
          :button_replacement_text => @game.players.length < @@min_players ? "You need #{@@min_players - @game.players.length} more players!" : nil,
          :next_state_button_text => "Start Game",
          :next_state_button_url => "/game/#{@game.id}/admin/#{@game.password}/start"
        },
        "running" => {
          :title => "Running",
          :description => "The Assassin Game is running. Wait for one player to win.",
          :button_replacement_type => "info",
          :button_replacement_text => "#{@game.remaining_players.length} players remaining."
        },
        "over" => {
          :title => "Over",
          :description => "The Assassin Game is over.",
          :button_replacement_type => "success",
          :button_replacement_text => @game.winner.nil? ? "No one won!" : "Winner: #{@game.winner.name}"
        }
      }
    @state = states[@game.state]
  end

  def invite
    game = game_by_id params[:id]
    check_admin_password game, params[:password]

    game.create_invitation params[:user_name]

    redirect_to game_admin_route game, "overview"
  end

  def invites
    game = game_by_id params[:id]
    check_admin_password game, params[:password]

    (1..params[:amount].to_i).each do |_|
      game.create_invitation
    end

    redirect_to game_admin_route game, "overview"
  end

  def start
    game = game_by_id params[:id]
    check_admin_password game, params[:password]

    game.running!

    players = game.players.shuffle
    for i in 0...players.length
      player = players[i]
      target = players[(i+1) % players.length]
      player.targets << target
    end

    redirect_to game_admin_route game, "overview"
  end

  def join_get_id
    unless params[:id].nil?
      unless params[:id].empty?
        redirect_to "/game/#{params[:id]}/join"
      else
        redirect_to "/game/join"
      end
    end
  end

  def join_form
    @game = game_by_id params[:id]
    raise GameNotJoinableException.new(@game.id, "/game/join?error=Game '#{@game.id}' is no longer joinable!") unless @game.join?

    @title = "Join #{@game.name}"

    if params[:invitation_token].nil?
      raise GameNotJoinableException.new(@game.id, "/game/join?error=Game '#{@game.id}' is invitation only!") if @game.invitation_only
    else
      @invitation = @game.invitations.where(:token => params[:invitation_token]).first
      raise GameNotJoinableException.new(@game.id, "/game/join?error=Your invitation token has already been used!") if @invitation.nil?
    end
  end

  def join
    game = game_by_id params[:id]

    raise GameNotJoinableException.new(@game.id, "/game/join?error=Game '#{@game.id}' is no longer joinable!") unless @game.join?

    if params[:invitation_token].nil?
      raise GameNotJoinableException.new(game.id, "/game/join?error=Game '#{game.id}' is invitation only!") if game.invitation_only
      user_name = params[:name]
    else
      invitation = game.invitations.where(:token => params[:invitation_token]).first
      raise GameNotJoinableException.new(game.id, "/game/join?error=Your invitation token has already been used!") if invitation.nil?
      user_name = invitation.name.nil? ? params[:name] : invitation.name
      Invitation.where(:token => invitation.token).first.destroy
    end

    player = game.create_player user_name, params[:email], params[:image_url]

    redirect_to "/game/#{game.id}/user/#{player.id}"
  end

  def user
    @game = game_by_id(params[:id])
    @user = @game.player_by_id params[:user_id]

    @title = "#{@game.name} - #{@user.name}"
  end

  def kill_target
    game = game_by_id(params[:id])
    player = game.player_by_id params[:user_id]
    target = player.target

    if params[:target_kill_pin] == target.kill_pin
      target.target.chaser = player
      target.chaser = nil
      target.save

      if game.remaining_players.length == 1
        game.over!
      end

      redirect_to "/game/#{game.id}/user/#{player.id}"
    else
      raise WrongKillPinException.new(params[:target_kill_pin], "/game/#{game.id}/user/#{player.id}?error=#{target.name}'s kill pin is not '#{params[:target_kill_pin]}'!")
    end
  end

  def game_admin_route(game, post_fix = "")
    "/game/#{game.id}/admin/#{game.password}/#{post_fix}"
  end

  def check_admin_password(game, password)
    raise WrongPasswordException.new(password, "/?error=Wrong admin password!!") if game.password != password
  end

  def game_by_id(game_id, fallback_url = "/game/join")
    fallback_url = "#{fallback_url}?error=Could not find a game with ID \'#{game_id}\'!"
    raise GameNotFoundException.new(game_id, fallback_url) if (game = Game.where(:id => game_id).first).nil?
    game
  end

  def redirect_exception(exception)
    redirect_to exception.fallback_url unless performed?
  end
end
