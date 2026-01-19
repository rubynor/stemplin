require "test_helper"

module Workspace
  class HolidaysControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    fixtures :all

    setup do
      @user = users(:organization_admin)
      sign_in @user
    end

    test "should get show" do
      get workspace_holidays_path
      assert_response :success
    end

    test "should get show with country code" do
      @user.current_organization.update(holiday_country_code: "us")
      get workspace_holidays_path
      assert_response :success
    end

    test "should update country code" do
      patch workspace_holidays_path, params: { organization: { holiday_country_code: "no" } }
      assert_redirected_to workspace_holidays_path
      assert_equal "no", @user.current_organization.reload.holiday_country_code
    end

    test "should not update with invalid country code" do
      patch workspace_holidays_path, params: { organization: { holiday_country_code: "invalid" } }
      assert_response :unprocessable_entity
    end

    test "should require authentication" do
      sign_out @user
      get workspace_holidays_path
      assert_redirected_to new_user_session_path
    end
  end
end
