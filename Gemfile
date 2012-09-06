source :rubygems

gem 'rails',          '~> 3.2.1'
gem 'passenger'
gem 'activerecord'
gem 'activesupport'
gem 'activeresource'
gem 'mysql2'
gem 'rest-client'
gem 'statsample'
gem 'capistrano'
gem 'daemons'
gem 'kaminari'
gem 'imgkit'
gem 'watir-webdriver'
gem 'watir-webdriver-performance'
gem 'watirgrid'
gem 'headless'
gem 'redis'
gem 'nokogiri'
gem 'uuidtools'
gem 'har'
gem 'tire'
gem 'resque', :require => 'resque/server'
gem 'foreman'
gem 'RedCloth', :require => 'redcloth'
gem 'grizzled-rails-logger'
gem 'jquery-rails'

group :assets do
  gem 'uglifier'
end

group :staging, :production do
  gem 'fog', :require => 'fog'
  gem 'omniauth-github'
  gem 'omniauth-google'
  gem 'omniauth-twitter'
  gem 'rack-google_analytics', :require => 'rack/google_analytics'
  gem 'airbrake'
  gem 'fat_zebra', :require => 'fat_zebra'
end

group :test, :development do
  gem 'fog', :require => 'fog'
  gem 'fat_zebra', :require => 'fat_zebra'
  gem 'rspec'				      
  gem 'rspec-rails'
  gem 'guard'         
  gem 'guard-rspec'
  gem 'guard-spork'
  gem 'guard-bundler'
  gem 'guard-rails'       
  gem 'growl'
  gem 'spork'
end

platforms :jruby do
  gem 'jruby-openssl'
  gem 'warbler'
  gem 'activerecord-jdbcmysql-adapter'
  gem 'activerecord-jdbch2-adapter'

  group :assets do
    gem 'therubyrhino'
  end

  group :development do
    gem 'jruby-lint'
  end
end