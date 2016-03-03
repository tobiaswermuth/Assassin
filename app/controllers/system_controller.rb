class SystemController < ActionController::Base
  layout "application"
  protect_from_forgery with: :exception

  def join
    unless params[:token].nil?
      redirect_to "/join/#{params[:token]}"
    end
  end

  def join_game
    unless known_game_token? params[:token]
      redirect_to "/join"
    end

    @game_name = "The ultimate Game"
  end

  def join_register

  end

  def known_game_token?(token)
    #TODO
    true
  end
end
