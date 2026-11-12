require "test_helper"
require_relative "base_test"

class Api::V1::ApiTokensControllerTest < Api::V1::BaseTest
  setup do
    @user = users(:joe)
    @token = @user.api_tokens.create!(name: "CLI")
    @headers = { "Authorization" => "Bearer #{@token.plaintext}" }
  end

  test "update returns a new secret for the token that made the request" do
    patch api_v1_api_token_path, headers: @headers

    assert_response :success
    assert_equal @token, ApiToken.find_by_plaintext(json_response["api_token"])
    assert_not_equal @token.plaintext, json_response["api_token"]
  end

  test "the old secret stops working after regeneration" do
    patch api_v1_api_token_path, headers: @headers
    assert_response :success

    get api_v1_organizations_path, headers: @headers
    assert_response :unauthorized
  end

  test "regenerating one token leaves the user's other tokens working" do
    other = @user.api_tokens.create!(name: "Server")

    patch api_v1_api_token_path, headers: @headers
    assert_response :success

    get api_v1_organizations_path, headers: { "Authorization" => "Bearer #{other.plaintext}" }
    assert_response :success
  end
end
