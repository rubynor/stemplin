require "test_helper"

module Profiles
  class PasswordsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:ron)
    end

    test "update requires sign in" do
      patch profile_password_path, params: { user: { current_password: "password", password: "new-secret-1", password_confirmation: "new-secret-1" } }

      assert_redirected_to new_user_session_path
      assert @user.reload.valid_password?("password")
    end

    test "the password changes when the current one is given and the new one is confirmed" do
      sign_in @user

      patch profile_password_path, params: { user: { current_password: "password", password: "new-secret-1", password_confirmation: "new-secret-1" } }

      assert_redirected_to profile_path
      assert @user.reload.valid_password?("new-secret-1")
    end

    test "the user stays signed in after changing the password" do
      sign_in @user
      patch profile_password_path, params: { user: { current_password: "password", password: "new-secret-1", password_confirmation: "new-secret-1" } }

      get profile_path

      assert_response :success
    end

    test "a wrong current password is rejected and explained in the password card" do
      sign_in @user

      patch profile_password_path, params: { user: { current_password: "wrong", password: "new-secret-1", password_confirmation: "new-secret-1" } }

      assert_response :unprocessable_entity
      assert @user.reload.valid_password?("password")
      assert_select "#profile_password", text: /is invalid/
      assert_select "#profile_personal", text: /is invalid/, count: 0
    end

    test "a confirmation that does not match is rejected" do
      sign_in @user

      patch profile_password_path, params: { user: { current_password: "password", password: "new-secret-1", password_confirmation: "new-secret-2" } }

      assert_response :unprocessable_entity
      assert @user.reload.valid_password?("password")
    end

    test "a blank new password is rejected instead of quietly keeping the old one" do
      sign_in @user

      patch profile_password_path, params: { user: { current_password: "password", password: "", password_confirmation: "" } }

      assert_response :unprocessable_entity
      assert_select "#profile_password", text: /can't be blank/
    end

    test "the password form cannot change other details" do
      sign_in @user

      patch profile_password_path, params: { user: { current_password: "password", password: "new-secret-1", password_confirmation: "new-secret-1", email: "new@example.com" } }

      assert_equal "ron@example.com", @user.reload.email
    end
  end
end
