module SentryHelper
  # Configures the browser SDK (app/javascript/sentry.js). Rendered only where
  # the Ruby SDK reports too, so development and test send nothing.
  def sentry_meta_tags
    dsn = ENV["SENTRY_FRONTEND_DSN"].presence || ENV["SENTRY_KEY"].presence
    return unless dsn && sentry_enabled?

    organization = current_user&.current_organization
    safe_join([
      tag.meta(name: "sentry-dsn", content: dsn),
      tag.meta(name: "sentry-environment", content: Rails.env),
      (tag.meta(name: "sentry-release", content: Sentry.configuration.release) if Sentry.configuration.release),
      (tag.meta(name: "sentry-user-id", content: current_user.id) if current_user),
      (tag.meta(name: "sentry-organization-id", content: organization.id) if organization)
    ].compact, "\n")
  end

  def sentry_enabled?
    Sentry.configuration&.enabled_in_current_env?
  end
end
