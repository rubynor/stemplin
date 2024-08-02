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
      post :create, params: { organization: { name: "Test Organization", currency: "SEK" } }
    end

    assert_not user.organizations.empty?
  end

  test "should not create an organization with invalid currency" do
    user = users(:org_admin_without_org)
    sign_in user

    assert user.organizations.empty?

    assert_no_difference("Organization.count") do
      post :create, params: { organization: { name: "Valid name", currency: "INVALID_CURRENCY_CODE" } }
    end

    assert user.organizations.empty?
  end
end
