require "test_helper"

class CleanupStaleOauthApplicationsJobTest < ActiveJob::TestCase
  test "removes stale dynamically registered applications with no tokens" do
    stale_app = Doorkeeper::Application.create!(
      name: "Stale App",
      redirect_uri: "http://localhost:8080/callback",
      scopes: "mcp",
      confidential: false,
      registration_ip: "1.2.3.4",
      created_at: 25.hours.ago
    )

    assert_difference "Doorkeeper::Application.count", -1 do
      CleanupStaleOauthApplicationsJob.perform_now
    end

    assert_not Doorkeeper::Application.exists?(stale_app.id)
  end

  test "keeps applications younger than 24 hours" do
    recent_app = Doorkeeper::Application.create!(
      name: "Recent App",
      redirect_uri: "http://localhost:8080/callback",
      scopes: "mcp",
      confidential: false,
      registration_ip: "1.2.3.4",
      created_at: 23.hours.ago
    )

    assert_no_difference "Doorkeeper::Application.count" do
      CleanupStaleOauthApplicationsJob.perform_now
    end

    assert Doorkeeper::Application.exists?(recent_app.id)
  end

  test "keeps applications that have tokens" do
    app = Doorkeeper::Application.create!(
      name: "Used App",
      redirect_uri: "http://localhost:8080/callback",
      scopes: "mcp",
      confidential: false,
      registration_ip: "1.2.3.4",
      created_at: 25.hours.ago
    )

    Doorkeeper::AccessToken.create!(
      application: app,
      resource_owner_id: users(:joe).id,
      scopes: "mcp",
      expires_in: 1.hour
    )

    assert_no_difference "Doorkeeper::Application.count" do
      CleanupStaleOauthApplicationsJob.perform_now
    end

    assert Doorkeeper::Application.exists?(app.id)
  end

  test "keeps applications without registration_ip (not dynamically registered)" do
    app = Doorkeeper::Application.create!(
      name: "Manual App",
      redirect_uri: "http://localhost:8080/callback",
      scopes: "mcp",
      confidential: false,
      registration_ip: nil,
      created_at: 25.hours.ago
    )

    assert_no_difference "Doorkeeper::Application.count" do
      CleanupStaleOauthApplicationsJob.perform_now
    end

    assert Doorkeeper::Application.exists?(app.id)
  end
end
