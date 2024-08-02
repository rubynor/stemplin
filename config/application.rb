require_relative "boot"

require "rails/all"
require "csv"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Stemplin
  class Application < Rails::Application
    config.autoload_paths << "#{root}/app/views"
    config.autoload_paths << "#{root}/app/views/layouts"
    config.autoload_paths << "#{root}/app/views/components"
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.i18n.available_locales = [ :en, :nb ]
    config.active_job.queue_adapter = :sidekiq

    # Using custom controller ErrorsController for exceptions
    config.exceptions_app = self.routes

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.to_prepare do
      Devise::SessionsController.layout "devise"
      Devise::RegistrationsController.layout "devise"
      Devise::ConfirmationsController.layout "devise"
      Devise::UnlocksController.layout "devise"
      Devise::PasswordsController.layout "devise"
    end

    config.http_host = if Rails.env.production?
      ENV.fetch("HTTP_HOST")
    else
      ENV.fetch("HTTP_HOST", "localhost:3000")
    end
    config.http_protocol = Rails.env.production? ? "https" : "http"
    config.http_url = "#{config.http_protocol}://#{config.http_host}".freeze

    config.emails = config_for(:emails)
    config.currencies = config_for(:currencies)
  end

  def self.config
    Application.config
  end
end
