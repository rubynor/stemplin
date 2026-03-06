require "test_helper"

class Oauth::DynamicRegistrationControllerTest < ActionDispatch::IntegrationTest
  test "creates application with valid params" do
    assert_difference "Doorkeeper::Application.count", 1 do
      post "/oauth/register", params: {
        client_name: "My MCP Client",
        redirect_uris: [ "http://localhost:8080/callback" ]
      }, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "My MCP Client", json["client_name"]
    assert json["client_id"].present?
    assert_equal [ "http://localhost:8080/callback" ], json["redirect_uris"]
    assert_equal [ "authorization_code" ], json["grant_types"]
    assert_equal [ "code" ], json["response_types"]
    assert_equal "none", json["token_endpoint_auth_method"]
    assert_equal "mcp", json["scope"]
  end

  test "creates application with default name" do
    post "/oauth/register", params: {
      redirect_uris: [ "http://localhost:8080/callback" ]
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "MCP Client", json["client_name"]
  end

  test "creates application with multiple redirect URIs" do
    post "/oauth/register", params: {
      client_name: "Multi-URI Client",
      redirect_uris: [ "http://localhost:8080/callback", "http://localhost:9090/callback" ]
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal 2, json["redirect_uris"].length
  end

  test "rejects registration without redirect_uris" do
    assert_no_difference "Doorkeeper::Application.count" do
      post "/oauth/register", params: { client_name: "Bad Client" }, as: :json
    end

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal "invalid_client_metadata", json["error"]
    assert_includes json["error_description"], "redirect_uris"
  end

  test "rejects registration with empty redirect_uris array" do
    assert_no_difference "Doorkeeper::Application.count" do
      post "/oauth/register", params: {
        client_name: "Bad Client",
        redirect_uris: []
      }, as: :json
    end

    assert_response :bad_request
  end

  test "rejects registration with redirect_uri to untrusted host" do
    assert_no_difference "Doorkeeper::Application.count" do
      post "/oauth/register", params: {
        client_name: "Evil Client",
        redirect_uris: [ "http://evil.com/callback" ]
      }, as: :json
    end

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal "invalid_client_metadata", json["error"]
  end

  test "allows registration with https://claude.ai redirect_uri" do
    post "/oauth/register", params: {
      client_name: "Claude Client",
      redirect_uris: [ "https://claude.ai/callback" ]
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal [ "https://claude.ai/callback" ], json["redirect_uris"]
  end

  test "allows registration with subdomain of claude.ai" do
    post "/oauth/register", params: {
      client_name: "Claude Sub Client",
      redirect_uris: [ "https://sub.claude.ai/callback" ]
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal [ "https://sub.claude.ai/callback" ], json["redirect_uris"]
  end

  test "created application is non-confidential" do
    post "/oauth/register", params: {
      client_name: "Public Client",
      redirect_uris: [ "http://localhost:8080/callback" ]
    }, as: :json

    assert_response :created
    app = Doorkeeper::Application.last
    assert_not app.confidential
  end

  test "truncates client_name exceeding 255 characters" do
    long_name = "A" * 300
    post "/oauth/register", params: {
      client_name: long_name,
      redirect_uris: [ "http://localhost:8080/callback" ]
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert_operator json["client_name"].length, :<=, 255
  end

  test "rejects registration with too many redirect_uris" do
    uris = 6.times.map { |i| "http://localhost:#{8080 + i}/callback" }

    assert_no_difference "Doorkeeper::Application.count" do
      post "/oauth/register", params: {
        client_name: "Too Many URIs",
        redirect_uris: uris
      }, as: :json
    end

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_includes json["error_description"], "too many redirect_uris"
  end

  test "rejects registration with redirect_uri exceeding max length" do
    long_uri = "http://localhost:8080/" + "a" * 2048

    assert_no_difference "Doorkeeper::Application.count" do
      post "/oauth/register", params: {
        client_name: "Long URI Client",
        redirect_uris: [ long_uri ]
      }, as: :json
    end

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_includes json["error_description"], "max length"
  end

  test "stores registration_ip on created application" do
    post "/oauth/register", params: {
      client_name: "IP Test Client",
      redirect_uris: [ "http://localhost:8080/callback" ]
    }, as: :json

    assert_response :created
    app = Doorkeeper::Application.last
    assert_not_nil app.registration_ip
  end

  test "rejects registration when IP has reached application limit" do
    Oauth::DynamicRegistrationController::MAX_APPLICATIONS_PER_IP.times do |i|
      Doorkeeper::Application.create!(
        name: "App #{i}",
        redirect_uri: "http://localhost:8080/callback",
        scopes: "mcp",
        confidential: false,
        registration_ip: "127.0.0.1"
      )
    end

    assert_no_difference "Doorkeeper::Application.count" do
      post "/oauth/register", params: {
        client_name: "One Too Many",
        redirect_uris: [ "http://localhost:8080/callback" ]
      }, as: :json
    end

    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal "too_many_registrations", json["error"]
  end
end
