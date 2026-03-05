require "test_helper"

class McpOauthFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:joe)
  end

  test "unauthenticated MCP request returns 401 with WWW-Authenticate header" do
    get "/mcp/sse"
    assert_response :unauthorized
    assert_includes response.headers["WWW-Authenticate"], "Bearer"
    assert_includes response.headers["WWW-Authenticate"], "resource_metadata="
    assert_includes response.headers["WWW-Authenticate"], "/.well-known/oauth-protected-resource"
  end

  test "protected resource metadata endpoint returns correct JSON" do
    get "/.well-known/oauth-protected-resource"
    assert_response :success

    json = JSON.parse(response.body)
    assert_includes json["authorization_servers"], "http://www.example.com"
    assert_equal [ "header" ], json["bearer_methods_supported"]
    assert_equal [ "mcp" ], json["scopes_supported"]
  end

  test "authorization server metadata endpoint returns correct JSON" do
    get "/.well-known/oauth-authorization-server"
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "http://www.example.com/oauth/authorize", json["authorization_endpoint"]
    assert_equal "http://www.example.com/oauth/token", json["token_endpoint"]
    assert_equal "http://www.example.com/oauth/register", json["registration_endpoint"]
    assert_equal [ "code" ], json["response_types_supported"]
    assert_equal [ "authorization_code" ], json["grant_types_supported"]
    assert_equal [ "none" ], json["token_endpoint_auth_methods_supported"]
    assert_equal [ "S256" ], json["code_challenge_methods_supported"]
    assert_equal [ "mcp" ], json["scopes_supported"]
  end

  test "dynamic client registration creates application" do
    assert_difference "Doorkeeper::Application.count", 1 do
      post "/oauth/register", params: {
        client_name: "Test MCP Client",
        redirect_uris: [ "http://localhost:3000/callback" ]
      }, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Test MCP Client", json["client_name"]
    assert json["client_id"].present?
    assert_equal [ "http://localhost:3000/callback" ], json["redirect_uris"]
    assert_equal "none", json["token_endpoint_auth_method"]
  end

  test "dynamic client registration fails without redirect_uris" do
    post "/oauth/register", params: { client_name: "Bad Client" }, as: :json
    assert_response :bad_request

    json = JSON.parse(response.body)
    assert_equal "invalid_client_metadata", json["error"]
  end

  test "MCP request with valid OAuth token succeeds" do
    app = Doorkeeper::Application.create!(
      name: "Test",
      redirect_uri: "http://localhost:3000/callback",
      scopes: "mcp",
      confidential: false
    )

    token = Doorkeeper::AccessToken.create!(
      application: app,
      resource_owner_id: @user.id,
      scopes: "mcp",
      expires_in: 1.hour
    )

    get "/mcp/sse", headers: { "Authorization" => "Bearer #{token.plaintext_token}" }

    # Should not be 401 — the request passes through to fast-mcp
    assert_not_equal 401, response.status
  end

  test "MCP request with expired token returns 401" do
    app = Doorkeeper::Application.create!(
      name: "Test",
      redirect_uri: "http://localhost:3000/callback",
      scopes: "mcp",
      confidential: false
    )

    token = Doorkeeper::AccessToken.create!(
      application: app,
      resource_owner_id: @user.id,
      scopes: "mcp",
      expires_in: 1.hour,
      created_at: 2.hours.ago
    )

    get "/mcp/sse", headers: { "Authorization" => "Bearer #{token.plaintext_token}" }
    assert_response :unauthorized
  end

  test "MCP request with revoked token returns 401" do
    app = Doorkeeper::Application.create!(
      name: "Test",
      redirect_uri: "http://localhost:3000/callback",
      scopes: "mcp",
      confidential: false
    )

    token = Doorkeeper::AccessToken.create!(
      application: app,
      resource_owner_id: @user.id,
      scopes: "mcp",
      expires_in: 1.hour,
      revoked_at: 1.minute.ago
    )

    get "/mcp/sse", headers: { "Authorization" => "Bearer #{token.plaintext_token}" }
    assert_response :unauthorized
  end

  test "MCP request with token without mcp scope returns 401" do
    app = Doorkeeper::Application.create!(
      name: "Test",
      redirect_uri: "http://localhost:3000/callback",
      scopes: "mcp",
      confidential: false
    )

    token = Doorkeeper::AccessToken.create!(
      application: app,
      resource_owner_id: @user.id,
      scopes: "read",
      expires_in: 1.hour
    )

    get "/mcp/sse", headers: { "Authorization" => "Bearer #{token.plaintext_token}" }
    assert_response :unauthorized
  end

  test "forged X-MCP-OAUTH-USER-ID header does not authenticate" do
    # A request with a forged (unsigned) user ID header but no valid Bearer token
    # should return 401, not pass through as authenticated
    get "/mcp/sse", headers: {
      "Authorization" => "Bearer invalid-token",
      "X-MCP-OAUTH-USER-ID" => @user.id.to_s
    }
    assert_response :unauthorized
  end

  test "full PKCE token exchange flow" do
    sign_in @user

    # Register a client
    post "/oauth/register", params: {
      client_name: "PKCE Test Client",
      redirect_uris: [ "http://localhost:3000/callback" ]
    }, as: :json
    assert_response :created
    client_id = JSON.parse(response.body)["client_id"]

    # Generate PKCE verifier and challenge
    code_verifier = SecureRandom.urlsafe_base64(32)
    code_challenge = Base64.urlsafe_encode64(
      Digest::SHA256.digest(code_verifier), padding: false
    )

    # Request authorization
    get "/oauth/authorize", params: {
      client_id: client_id,
      redirect_uri: "http://localhost:3000/callback",
      response_type: "code",
      scope: "mcp",
      code_challenge: code_challenge,
      code_challenge_method: "S256"
    }
    assert_response :success

    # Approve authorization
    post "/oauth/authorize", params: {
      client_id: client_id,
      redirect_uri: "http://localhost:3000/callback",
      response_type: "code",
      scope: "mcp",
      code_challenge: code_challenge,
      code_challenge_method: "S256"
    }
    assert_response :redirect
    redirect_uri = URI.parse(response.location)
    code = Rack::Utils.parse_query(redirect_uri.query)["code"]
    assert code.present?, "Authorization code should be present"

    # Exchange code for token
    post "/oauth/token", params: {
      grant_type: "authorization_code",
      code: code,
      client_id: client_id,
      redirect_uri: "http://localhost:3000/callback",
      code_verifier: code_verifier
    }
    assert_response :success

    token_json = JSON.parse(response.body)
    assert token_json["access_token"].present?
    assert token_json["refresh_token"].present?
    assert_equal "Bearer", token_json["token_type"]
    assert_equal "mcp", token_json["scope"]
  end

  test "rejects plain PKCE code challenge method" do
    sign_in @user

    post "/oauth/register", params: {
      client_name: "Plain PKCE Client",
      redirect_uris: [ "http://localhost:3000/callback" ]
    }, as: :json
    assert_response :created
    client_id = JSON.parse(response.body)["client_id"]

    code_verifier = SecureRandom.urlsafe_base64(32)

    get "/oauth/authorize", params: {
      client_id: client_id,
      redirect_uri: "http://localhost:3000/callback",
      response_type: "code",
      scope: "mcp",
      code_challenge: code_verifier,
      code_challenge_method: "plain"
    }

    # Doorkeeper should reject plain challenge method
    assert_includes [ 400, 422 ], response.status,
      "Expected plain PKCE to be rejected, got #{response.status}"
  end

  test "non-MCP requests are not affected by middleware" do
    get "/api/v1/organizations", headers: { "Authorization" => "Bearer invalid" }
    # API controller handles its own auth — middleware's WWW-Authenticate with resource_metadata should not be present
    if response.status == 401
      www_auth = response.headers["WWW-Authenticate"]
      assert_not_includes(www_auth.to_s, "resource_metadata=")
    end
  end
end
