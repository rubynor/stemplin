require "test_helper"

module Workspace
  class IntegrationsControllerTest < ActionController::TestCase
    test "admin sees the integrations" do
      admin = users(:organization_admin)
      sign_in admin
      admin.current_organization.create_tripletex_integration!(employee_token: "secret-token", company_name: "Firma AS")

      get :show

      assert_response :success
      assert_includes response.body, "Firma AS"
    end

    test "members cannot see the integrations" do
      sign_in users(:organization_user)
      get :show
      assert_redirected_to root_path
    end
  end
end
