source ENV['GEM_SERVER_URL'] || 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "b743c64"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.1'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# For sending metrics to prometheus
gem 'prometheus-client'

gem 'tzinfo-data'

# Sending metrics to DataDog
gem 'dogapi'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem 'dotenv-rails'
  gem 'pry'
end

group :production do
  gem 'connect_vva', git: "https://github.com/department-of-veterans-affairs/connect_vva.git", branch: 'master'
  gem 'bgs', git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", branch: 'master'
  gem 'activerecord-oracle_enhanced-adapter', '~> 1.7.0'
  gem 'ruby-oci8'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
end

# new sha for dev/uat/preprod/demo
if ENV["CONNECT_VBMS_ENV"] == "uat" || ENV["CONNECT_VBMS_ENV"] == "preprod" || ENV["CONNECT_VBMS_ENV"] == "demo"
  gem "connect_vbms", git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", ref: "1a2d9b2d293935d5cf1b2088a1667820d783fcf6"
else
  gem "connect_vbms", git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", ref: "783200ca61b57fc75f818334838181993535229a"
end
