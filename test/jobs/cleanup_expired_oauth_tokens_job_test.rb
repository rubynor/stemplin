require "test_helper"

class CleanupExpiredOauthTokensJobTest < ActiveJob::TestCase
  setup do
    @app = Doorkeeper::Application.create!(
      name: "Test App",
      redirect_uri: "http://localhost:8080/callback",
      scopes: "mcp",
      confidential: false
    )
    @user = users(:joe)
  end

  test "removes tokens expired more than 30 days ago" do
    old_token = Doorkeeper::AccessToken.create!(
      application: @app,
      resource_owner_id: @user.id,
      scopes: "mcp",
      expires_in: 3600,
      created_at: 32.days.ago
    )

    assert_difference "Doorkeeper::AccessToken.count", -1 do
      CleanupExpiredOauthTokensJob.perform_now
    end

    assert_not Doorkeeper::AccessToken.exists?(old_token.id)
  end

  test "keeps recently expired tokens" do
    recent_token = Doorkeeper::AccessToken.create!(
      application: @app,
      resource_owner_id: @user.id,
      scopes: "mcp",
      expires_in: 3600,
      created_at: 2.days.ago
    )

    assert_no_difference "Doorkeeper::AccessToken.count" do
      CleanupExpiredOauthTokensJob.perform_now
    end

    assert Doorkeeper::AccessToken.exists?(recent_token.id)
  end

  test "removes tokens revoked more than 30 days ago" do
    revoked_token = Doorkeeper::AccessToken.create!(
      application: @app,
      resource_owner_id: @user.id,
      scopes: "mcp",
      expires_in: 3600,
      revoked_at: 31.days.ago
    )

    assert_difference "Doorkeeper::AccessToken.count", -1 do
      CleanupExpiredOauthTokensJob.perform_now
    end

    assert_not Doorkeeper::AccessToken.exists?(revoked_token.id)
  end

  test "keeps recently revoked tokens" do
    recent_revoked = Doorkeeper::AccessToken.create!(
      application: @app,
      resource_owner_id: @user.id,
      scopes: "mcp",
      expires_in: 3600,
      revoked_at: 5.days.ago
    )

    assert_no_difference "Doorkeeper::AccessToken.count" do
      CleanupExpiredOauthTokensJob.perform_now
    end

    assert Doorkeeper::AccessToken.exists?(recent_revoked.id)
  end

  test "removes expired grants older than 30 days" do
    old_grant = Doorkeeper::AccessGrant.create!(
      application: @app,
      resource_owner_id: @user.id,
      token: SecureRandom.hex(20),
      scopes: "mcp",
      expires_in: 600,
      redirect_uri: "http://localhost:8080/callback",
      created_at: 32.days.ago
    )

    assert_difference "Doorkeeper::AccessGrant.count", -1 do
      CleanupExpiredOauthTokensJob.perform_now
    end

    assert_not Doorkeeper::AccessGrant.exists?(old_grant.id)
  end
end
