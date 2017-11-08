Rails.application.routes.draw do

  scope "#{Rails.application.config.app_url_prefix}" do
    get "/" => 'monitor#index'
    get "/sample" => 'sample#index'
    get "/services" => 'sample#services'
  end

end
