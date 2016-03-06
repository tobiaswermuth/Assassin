class GameController < ActionController::Base
  include RedirectionHelper

  layout "application"
  protect_from_forgery with: :null_session

  @@games = {}

  def do_create
    game = Game.new params[:name], params[:rules]
    @@games[game.id] = game

    redirect game_admin_route game, "overview"
  end

  def overview
    @game = game_by_id params[:id], "/"

    redirect_if @game.password != params[:password], "/"
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

    redirect game_admin_route game, "overview"
  end

  def join_get_id
    redirect_if !params[:id].nil?, "/game/#{params[:id]}/join"
  end

  def join_form
    @game = game_by_id params[:id]
  end

  def join
    game = game_by_id params[:id]

    user = User.new params[:name], params[:email], params[:image_url], game
    game.users[user.id] = user

    redirect "/game/#{game.id}/user/#{user.id}"
  end

  def user
    @user = game_by_id(params[:id]).user_by_id params[:user_id]
  end

  def kill
    params[:user_id]
    params[:enemy_user_id]
    params[:enemy_pin]
  end

  def game_admin_route(game, post_fix = "")
    "/game/#{game.id}/admin/#{game.password}/#{post_fix}"
  end

  def game_by_id(game_id, fallback_url = "/game/join_get_id")
    redirect_if((game = @@games[game_id]).nil?, fallback_url)
    game
  end
end
