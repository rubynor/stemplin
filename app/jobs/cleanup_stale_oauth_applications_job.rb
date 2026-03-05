# frozen_string_literal: true

class CleanupStaleOauthApplicationsJob < ApplicationJob
  queue_as :default

  def perform
    # Remove dynamically registered applications older than 24 hours
    # that have never been used (no tokens or grants issued)
    stale_apps = Doorkeeper::Application
      .where.not(registration_ip: nil)
      .where(created_at: ...24.hours.ago)
      .where.not(id: Doorkeeper::AccessToken.select(:application_id))
      .where.not(id: Doorkeeper::AccessGrant.select(:application_id))

    count = stale_apps.delete_all
    Rails.logger.info("[CleanupStaleOauthApplicationsJob] Removed #{count} stale OAuth applications")
  end
end
