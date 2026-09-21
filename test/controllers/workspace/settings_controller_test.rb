require "test_helper"

module Workspace
  class SettingsControllerTest < ActionController::TestCase
    setup do
      @admin = users(:organization_admin)
      @organization = @admin.current_organization
      sign_in @admin
    end

    test "should show settings" do
      get :show
      assert_response :success
      assert_equal @organization, assigns(:organization)
    end

    test "should get edit with the list of currencies" do
      get :edit
      assert_response :success
      assert_includes assigns(:available_currencies), :NOK
    end

    test "should update currency and time copying" do
      assert_equal "USD", @organization.currency
      assert_not @organization.advanced_time_copying

      patch :update, params: { organization: { currency: "NOK", advanced_time_copying: "1" } }

      assert_redirected_to workspace_settings_path
      @organization.reload
      assert_equal "NOK", @organization.currency
      assert @organization.advanced_time_copying
    end

    test "should not update to an unknown currency" do
      patch :update, params: { organization: { currency: "NOPE" } }

      assert_response :unprocessable_entity
      assert_equal "USD", @organization.reload.currency
    end

    test "settings only ever apply to the current organization" do
      other = organizations(:organization_two)
      patch :update, params: { id: other.id, organization: { currency: "NOK" } }

      assert_equal "EUR", other.reload.currency
      assert_equal "NOK", @organization.reload.currency
    end

    test "member cannot see or change settings" do
      sign_in users(:organization_user)

      get :show
      assert_redirected_to root_path
      get :edit
      assert_redirected_to root_path
      patch :update, params: { organization: { currency: "NOK" } }
      assert_redirected_to root_path
      assert_equal "USD", @organization.reload.currency
    end

    test "spectator cannot see or change settings" do
      sign_in users(:organization_spectator)

      get :show
      assert_redirected_to reports_path
      patch :update, params: { organization: { currency: "NOK" } }
      assert_redirected_to reports_path
      assert_equal "USD", @organization.reload.currency
    end
  end
end
