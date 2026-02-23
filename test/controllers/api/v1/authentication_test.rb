require "test_helper"
require_relative "base_test"

class Api::V1::AuthenticationTest < Api::V1::BaseTest
  test "returns 401 without token" do
    get api_v1_organizations_path
    assert_response :unauthorized
    assert_equal "Unauthorized", json_response["error"]
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
end
