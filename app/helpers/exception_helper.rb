module ExceptionHelper
  class RedirectionException < StandardError
    attr_reader :id, :fallback_url
    def initialize(id, fallback_url)
      @id = id
      @fallback_url = fallback_url
    end
  end

  class WrongPasswordException < RedirectionException
  end

  class GameNotFoundException < RedirectionException
  end

  class UserNotFoundException < RedirectionException
  end

  class GameNotJoinableException < RedirectionException
  end

  class WrongKillPinException < RedirectionException
  end
end
