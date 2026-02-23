require "test_helper"
require_relative "base_test"

class Api::V1::UsersControllerTest < Api::V1::BaseTest
  setup do
    @user = users(:joe)
    @admin = users(:organization_admin)
  end

  test "me returns current user info" do
    get me_api_v1_users_path, headers: api_headers(@user)
    assert_response :success
    assert_equal @user.email, json_response["email"]
    assert_equal @user.name, json_response["name"]
    assert json_response.key?("api_token")
    assert json_response.key?("current_organization")
  end

  test "index returns organization users for admin" do
    get api_v1_users_path, headers: api_headers(@admin)
    assert_response :success
    assert_kind_of Array, json_response
  end

end
