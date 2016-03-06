module RedirectionHelper
  def redirect_if(requirement, url)
    redirect(url) if requirement
  end

  def redirect(url)
    redirect_to(url) unless performed?
  end
end
