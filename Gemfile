source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 6.1.3', '>= 6.1.3.2'
# Use postgresql as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 5.5.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'

gem 'aws-sdk-s3'
gem 'daemons'
gem 'delayed_job_active_record'
gem 'dotenv-rails'
gem 'down'
gem 'httparty'
gem 'marcel'
gem 'oauth'
gem 'rbnacl', git: 'https://github.com/RubyCrypto/rbnacl'
gem 'solana_rpc_ruby', git: 'https://github.com/richard-fisher/solana-rpc-ruby'
gem 'twitter'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
end

group :development do
  gem 'listen', '~> 3.3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "capistrano", "~> 3.17", require: false
  gem 'capistrano-asdf'
  gem 'capistrano-bundler', '~> 2.0'
  gem 'spring'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem "bugsnag", "~> 6.24"

gem 'will_paginate'

gem 'activerecord-import'
gem 'mini_magick'
gem 'cloudinary'
gem 'actioncable'