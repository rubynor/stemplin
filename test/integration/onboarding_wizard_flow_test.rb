require "test_helper"

class OnboardingWizardFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "user is guided through all onboarding wizard steps" do
    # Organization step
    get "/onboarding_wizard/organization"
    assert_response :success

    patch "/onboarding_wizard/organization", params: {
      organization: { name: "Test Org", currency: "USD" }
    }
    assert_redirected_to "/onboarding_wizard/setup_choice"
    follow_redirect!

    # Setup choice step
    get "/onboarding_wizard/client"
    assert_response :success

    # Client step
    patch "/onboarding_wizard/client", params: {
      client: { name: "Test Client" }
    }
    assert_redirected_to "/onboarding_wizard/project"
    follow_redirect!

    # Project step
    patch "/onboarding_wizard/project", params: {
      project: { name: "Test Project" }
    }
    assert_redirected_to "/onboarding_wizard/tasks"
    follow_redirect!

    # Tasks step
    patch "/onboarding_wizard/tasks", params: {
      task: { name: "Test Task" }
    }
    assert_redirected_to "/onboarding_wizard/finish"
    follow_redirect!

    # Finish step
    assert_response :success
  end

  test "user can skip onboarding wizard" do
    get skip_onboarding_wizard_path
    assert_redirected_to root_path
  end

  test "user is redirected to organization step when trying to access workspace without organization" do
    get root_path
    assert_redirected_to onboarding_wizard_path(:organization)
  end
end
