require "test_helper"
require_relative "base_test"

class Api::V1::ApiTokensControllerTest < Api::V1::BaseTest
  setup do
    @user = users(:joe)
  end

  test "update regenerates token" do
    old_token = @user.ensure_api_token!
    patch api_v1_api_token_path, headers: api_headers(@user)
    assert_response :success
    assert json_response.key?("api_token")
    assert_not_equal old_token, json_response["api_token"]
  end

  test "old token stops working after regeneration" do
    @user.ensure_api_token!
    old_headers = { "Authorization" => "Bearer #{@user.api_token}" }

    patch api_v1_api_token_path, headers: old_headers
    assert_response :success

    get api_v1_organizations_path, headers: old_headers
    assert_response :unauthorized
  end
end
