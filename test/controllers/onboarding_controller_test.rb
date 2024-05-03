require "test_helper"

class OnboardingControllerTest < ActionController::TestCase
  test "should redirect a user with an organization to root_path" do
    user = users(:organization_admin)
    sign_in user

    get :new
    assert_redirected_to root_path
  end

  test "should create an organization and associate it with the current user" do
    user = users(:org_admin_without_org)
    sign_in user

    assert user.organizations.empty?

    assert_difference("Organization.count") do
      post :create, params: { organization: { name: "Test Organization" } }
    end

    assert_not user.organizations.empty?
  end

  test "should allow newly invited user to update their password" do
    newly_invited_user = users(:newly_invited_user)
    sign_in newly_invited_user

    assert_not newly_invited_user.is_verified

    patch :update_password, params: { user: { password: "new_password", password_confirmation: "new_password", current_password: "password" } }

    assert newly_invited_user.reload.is_verified
  end

  test "should allow user to skip and verify their account" do
    user = users(:newly_invited_user)
    sign_in user

    assert_not user.is_verified

    patch :skip_and_verify_account

    assert user.reload.is_verified
  end
end
