source ENV['GEM_SERVER_URL'] || 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "b743c64"

gem 'rails', '~> 5.2.4.2'
gem 'sqlite3'
gem 'puma', '~> 5.6'
gem 'sass-rails', '~> 5.0', '>= 5.0.6'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2', '>= 4.2.1'
gem 'jquery-rails', '>= 4.3.1'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'
gem 'dogapi'
gem 'logstasher'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem 'dotenv-rails', '>= 2.1.2'
  gem 'pry'
end


group :production do
  gem 'connect_vbms', git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", branch: 'master'
  gem 'connect_vva', git: "https://github.com/department-of-veterans-affairs/connect_vva.git", branch: 'master'
  gem 'bgs', git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", branch: 'master'
  gem 'activerecord-oracle_enhanced-adapter', '~> 5.2.0'
  gem 'ruby-oci8'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.4.0'
  gem 'listen', '~> 3.0.8'
end
