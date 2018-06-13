Rails.application.routes.draw do

  scope "#{Rails.application.config.app_url_prefix}" do
    get "/" => 'monitor#index'  
    
    get "/health-check", to: "health_checks#show"
    # We may be able to deprecate /sample now that /health-check exists.
    get "/sample" => 'sample#index'
    get "/availability_report" => 'sample#availability_report'
  end

end
