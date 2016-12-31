Rails.application.routes.draw do

  resource :monitor

  resource :info

  get "sample" => "sample#index"

  root 'monitor#index'

end
