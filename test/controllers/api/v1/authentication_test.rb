require "test_helper"
require_relative "base_test"

class Api::V1::AuthenticationTest < Api::V1::BaseTest
  test "returns 401 without token" do
    get api_v1_organizations_path
    assert_response :unauthorized
    assert_includes json_response["errors"], "Unauthorized"
  end

  test "returns 401 with invalid token" do
    get api_v1_organizations_path, headers: { "Authorization" => "Bearer invalid_token" }
    assert_response :unauthorized
  end

  test "returns 200 with valid token" do
    user = users(:joe)
    get api_v1_organizations_path, headers: api_headers(user)
    assert_response :success
  end

  test "X-Organization-Id switches organization context" do
    admin = users(:organization_admin)
    org_two = organizations(:organization_two)

    get api_v1_clients_path, headers: api_headers(admin, organization: org_two)
    assert_response :success

    client_names = json_response.map { |c| c["name"] }
    assert_includes client_names, "F Corp"
    assert_not_includes client_names, "E Corp"
  end

  test "falls back to default organization when X-Organization-Id is not set" do
    user = users(:joe)
    get api_v1_clients_path, headers: api_headers(user)
    assert_response :success
  end

  test "X-Organization-Id returns 404 for non-member organization" do
    user = users(:joe)
    other_org = organizations(:organization_two)

    get api_v1_clients_path, headers: api_headers(user, organization: other_org)
    assert_response :not_found
  end
end
