Rails.application.routes.draw do

  resource :monitor

  root 'monitor#new'

  # get "unauthorized" => "application#unauthorized"
  # get "health-check" => "health_checks#show"
  # get "admin" => "feedback#admin"

end
