Sentry.init do |config|
  config.dsn = "https://274b343b6ec0445dae647ef9794442f6@sentry.rubynor.com/16"
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production.
  config.traces_sample_rate = 1.0
  # or
  config.traces_sampler = lambda do |context|
    true
  end
end
