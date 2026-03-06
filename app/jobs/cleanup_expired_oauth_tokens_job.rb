# frozen_string_literal: true

class CleanupExpiredOauthTokensJob < ApplicationJob
  queue_as :default

  def perform
    cutoff = 30.days.ago

    expired_count = Doorkeeper::AccessToken
      .where("created_at + (expires_in * interval '1 second') < ?", cutoff)
      .delete_all

    revoked_count = Doorkeeper::AccessToken
      .where(revoked_at: ...cutoff)
      .delete_all

    expired_grants = Doorkeeper::AccessGrant
      .where("created_at + (expires_in * interval '1 second') < ?", cutoff)
      .delete_all

    Rails.logger.info(
      "[CleanupExpiredOauthTokensJob] Removed #{expired_count} expired tokens, " \
      "#{revoked_count} revoked tokens, #{expired_grants} expired grants"
    )
  end
end
