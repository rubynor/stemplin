require "test_helper"

class OnboardingWizardFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one) # assumes a user fixture named :one
    sign_in @user
    # Create an organization and associate it with the user
    @organization = organizations(:one) || Organization.create!(name: "Org", currency: "USD")
    AccessInfo.create!(user: @user, organization: @organization, role: :organization_admin)
  end

  test "user is guided through all onboarding wizard steps" do
    # Start at client step
    get "/onboarding_wizard/client"
    assert_response :success
    assert_select "h2", text: /client/i

    # Post client
    assert_difference "Client.count" do
      patch "/onboarding_wizard/client", params: { client: { name: "Test Client" } }
    end
    assert_redirected_to "/onboarding_wizard/project"
    follow_redirect!

    # Debug session state
    puts "Session after client creation: #{session.to_h}"

    # Project step
    assert_select "h2", text: /project/i
    assert_difference "Project.count" do
      patch "/onboarding_wizard/project", params: { project: { name: "Test Project" } }
    end
    assert_redirected_to "/onboarding_wizard/tasks"
    follow_redirect!

    # Tasks step
    assert_select "h2", text: /tasks/i
    assert_difference "Task.count" do
      patch "/onboarding_wizard/tasks", params: { task: { name: "Test Task" } }
    end
    assert_redirected_to "/onboarding_wizard/finish"
    follow_redirect!

    # Finish step
    assert_select "h2", text: /done/i
  end

  test "user can skip onboarding wizard" do
    get skip_onboarding_wizard_path
    assert_redirected_to root_path
  end
end 