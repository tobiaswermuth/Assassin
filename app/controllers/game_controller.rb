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

  @@games = {}
  @@no_user_name = "[[{{((no_user_name))}}]]"
  helper_method :no_user_name
  def no_user_name; @@no_user_name end
  @@min_players = 2


  def do_create
    game = Game.new params[:name], params[:rules], !params[:invitation_only].nil?
    @@games[game.id] = game

    redirect_to game_admin_route game, "overview"
  end

  def overview
    @game = game_by_id params[:id], "/"
    check_admin_password @game, params[:password]

    @title = "#{@game.name} - Administration"
    states = {
        :join => {
          :title => "Join",
          :description => "Players are able to join the Assassin Game.",
          :button_replacement_type => "warning",
          :button_replacement_text => @game.users.length < @@min_players ? "You need #{@@min_players - @game.users.length} more players!" : nil,
          :next_state_button_text => "Start Game",
          :next_state_button_url => "/game/#{@game.id}/admin/#{@game.password}/start"
        },
        :running => {
          :title => "Running",
          :description => "The Assassin Game is running. Wait for one player to win.",
          :button_replacement_type => "info",
          :button_replacement_text => "#{@game.remaining_users.length} players remaining."
        },
        :over => {
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
      game.create_invitation @@no_user_name
    end

    redirect_to game_admin_route game, "overview"
  end

  def start
    game = game_by_id params[:id]
    check_admin_password game, params[:password]

    game.state = :running

    users = game.users.values.shuffle
    for i in 0...users.length
      user = users[i]
      target = users[(i+1) % users.length]
      user.target = target
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
    raise GameNotJoinableException.new(@game.id, "/game/join?error=Game '#{@game.id}' is no longer joinable!") if @game.state != :join

    @title = "Join #{@game.name}"

    if params[:invitation_token].nil?
      raise GameNotJoinableException.new(@game.id, "/game/join?error=Game '#{@game.id}' is invitation only!") if @game.invitation_only
    else
      @invitation_token = params[:invitation_token]
      @invitation_user_name = @game.invitations[@invitation_token]
      raise GameNotJoinableException.new(@game.id, "/game/join?error=Your invitation token has already been used!") if @invitation_user_name.nil?
    end
  end

  def join
    game = game_by_id params[:id]

    if params[:invitation_token].nil?
      raise GameNotJoinableException.new(game.id, "/game/join?error=Game '#{game.id}' is invitation only!") if game.invitation_only
      user_name = params[:name]
    else
      invitation_token = params[:invitation_token]
      invitation_user_name = game.invitations[invitation_token]
      raise GameNotJoinableException.new(game.id, "/game/join?error=Your invitation token has already been used!") if invitation_user_name.nil?
      user_name = invitation_user_name == @@no_user_name ? params[:name] : invitation_user_name
      game.delete_invitation invitation_token
    end

    user = User.new user_name, params[:email], params[:image_url]
    game.users[user.id] = user

    redirect_to "/game/#{game.id}/user/#{user.id}"
  end

  def user
    @game = game_by_id(params[:id])
    @user = @game.user_by_id params[:user_id]

    @title = "#{@game.name} - #{@user.name}"
  end

  def kill_target
    game = game_by_id(params[:id])
    user = game.user_by_id params[:user_id]
    target = user.target

    if params[:target_kill_pin] == target.kill_pin
      user.target = target.target
      target.target = nil
      target.killer = user

      if game.remaining_users.length == 1
        game.state = :over
      end

      redirect_to "/game/#{game.id}/user/#{user.id}"
    else
      raise GameNotJoinableException.new(params[:target_kill_pin], "/game/#{game.id}/user/#{user.id}?error=#{target.name}'s kill pin is not '#{params[:target_kill_pin]}'!")
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
    raise GameNotFoundException.new(game_id, fallback_url) if (game = @@games[game_id]).nil?
    game
  end

  def redirect_exception(exception)
    redirect_to exception.fallback_url unless performed?
  end
end
