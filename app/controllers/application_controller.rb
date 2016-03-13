class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  layout "application"
  protect_from_forgery with: :null_session

  @@titles = {
    "index" => "The Assassin Game - Alpha",
    "about" => "About",
    "terms" => "Terms and Conditions",
    "privacy" => "Privacy Policy",
  }

  before_action {
    @title = @@titles[action_name]
  }

end
