Rails.application.routes.draw do

  root :to => redirect("#{Rails.application.config.app_url_prefix}")

  scope "#{Rails.application.config.app_url_prefix}" do
    get "/" => 'monitor#index'
    get "/sample" => 'sample#index'
  end

end
