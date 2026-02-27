require "test_helper"
require_relative "base_test"

class Api::V1::ApiTokensControllerTest < Api::V1::BaseTest
  setup do
    @user = users(:joe)
  end

  test "update regenerates token" do
    token = @user.ensure_api_token!
    old_digest = @user.api_token_digest

    patch api_v1_api_token_path, headers: { "Authorization" => "Bearer #{token}" }
    assert_response :success
    assert json_response.key?("api_token")

    @user.reload
    assert_not_equal old_digest, @user.api_token_digest
  end

  test "old token stops working after regeneration" do
    token = @user.ensure_api_token!
    old_headers = { "Authorization" => "Bearer #{token}" }

    patch api_v1_api_token_path, headers: old_headers
    assert_response :success

    get api_v1_organizations_path, headers: old_headers
    assert_response :unauthorized
  end
end
