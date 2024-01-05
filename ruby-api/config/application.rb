require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
# require "sprockets/railtie"
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SolstaApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.active_job.queue_adapter = :delayed_job

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.sign_message = 'Welcome to Collector! Please sign this message to log-in. '
    # config.sign_message = 'Welcome to Collector! Dive into a world where you can collect, curate, and discover beautiful art. By signing or approving this message, you confirm the ownership of this wallet address. This action is completely free and you will not be charged. '
    config.destination_address = 'RyvoTTxHVn48GaAA26d8TfBqZcrkVHN4Fyo2LsucTtV'
    config.monthly = 1000000000
    config.yearly = 8000000000

    config.logger = Logtail::Logger.create_default_logger("rryqu8e9b6a7mfD9ZDr9gxdk")
  end
end
