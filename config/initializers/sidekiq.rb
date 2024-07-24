require "sidekiq"
require "sidekiq-scheduler"

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") } unless Rails.env.test?

  # TODO: Uncomment the statements below when we start adding schedules in `../sidekiq_scheduler.yml`
  # config.on(:startup) do
  #   Sidekiq.schedule = YAML.load_file(File.expand_path("../sidekiq_scheduler.yml", File.dirname(__FILE__)))
  #   SidekiqScheduler::Scheduler.instance.reload_schedule!
  # end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") } unless Rails.env.test?
end
