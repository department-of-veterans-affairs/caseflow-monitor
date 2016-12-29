class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def logo_class
    "cf-logo-image-default"
  end
  helper_method :logo_class
end
