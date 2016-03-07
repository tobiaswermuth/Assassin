class GameController < ActionController::Base
  include ExceptionHelper

  layout "application"
  protect_from_forgery with: :null_session

  rescue_from RedirectionException, :with => :redirect_exception

  @@games = {}

  @@titles = {
    "index" => "Welcome to Assassin",
    "create" => "Create a new Assassin Game",
    "join_get_id" => "Join an Assassin Game",
    "user" => "Your Game Overview"
  }

  before_action {
    @title = @@titles[action_name]
  }

  def do_create
    game = Game.new params[:name], params[:rules], !params[:invitation_only].nil?
    @@games[game.id] = game

    redirect_to game_admin_route game, "overview"
  end

  def overview
    @game = game_by_id params[:id], "/"
    redirect_to "/" if @game.password != params[:password]

    @title = "#{@game.name} - Administration"
  end

  def start
    game = game_by_id params[:id]
    game.state = :running

    users_to_assign = game.users.values
    first_user = users_to_assign.first
    while users_to_assign.length > 0
      user = users_to_assign.first
      users_to_assign = users_to_assign.reject{|_| _ == user}
      if users_to_assign.length > 0
        user.target = users_to_assign.sample
      else
        user.target = first_user
      end
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
  end

  def join
    game = game_by_id params[:id]

    user = User.new params[:name], params[:email], params[:image_url], game
    game.users[user.id] = user

    redirect_to "/game/#{game.id}/user/#{user.id}"
  end

  def user
    @game = game_by_id(params[:id])
    @user = @game.user_by_id params[:user_id]
  end

  def kill_target
    game = game_by_id(params[:id])
    user = game.user_by_id params[:user_id]
    target = user.target

    if params[:target_kill_pin] == target.kill_pin
      user.target = target.target
      target.target = nil

      if game.remaining_users.length == 1
        game.state = :over
      end

      redirect_to "/game/#{game.id}/user/#{user.id}"
    else
      raise GameNotJoinableException.new(params[:target_kill_pin], "/game/#{game.id}/user/#{user.id}?error=#{target.name}'s kill pin is not #{params[:target_kill_pin]}!")
    end
  end

  def game_admin_route(game, post_fix = "")
    "/game/#{game.id}/admin/#{game.password}/#{post_fix}"
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
