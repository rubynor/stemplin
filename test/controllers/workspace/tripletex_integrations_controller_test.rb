require "test_helper"

module Workspace
  class TripletexIntegrationsControllerTest < ActionController::TestCase
    setup do
      @admin = users(:organization_admin)
      @organization = @admin.current_organization
      sign_in @admin
    end

    teardown { FakeTripletexApi.reset }

    test "shows the setup flow" do
      get :new
      assert_response :success
    end

    test "connects with a verified employee token and stores it encrypted" do
      FakeTripletexApi.install

      post :create, params: { tripletex_integration: { employee_token: " secret-token " } }

      assert_redirected_to workspace_integrations_path
      integration = @organization.reload.tripletex_integration
      assert_equal "secret-token", integration.employee_token
      assert_equal "Firma AS", integration.company_name
      assert_equal 42, integration.company_id
      assert_not_includes TripletexIntegration.connection.select_value("select employee_token from tripletex_integrations where id = #{integration.id}"), "secret-token"
    end

    test "does not connect when Tripletex rejects the token" do
      FakeTripletexApi.install(FakeTripletexApi.new(error: "Tripletex avviste nøkkelen."))

      post :create, params: { tripletex_integration: { employee_token: "wrong" } }

      assert_response :unprocessable_entity
      assert_nil @organization.reload.tripletex_integration
    end

    test "requires a token" do
      post :create, params: { tripletex_integration: { employee_token: "" } }

      assert_response :unprocessable_entity
      assert_nil @organization.reload.tripletex_integration
    end

    test "disconnects" do
      @organization.create_tripletex_integration!(employee_token: "secret-token")

      delete :destroy

      assert_redirected_to workspace_integrations_path
      assert_nil @organization.reload.tripletex_integration
    end

    test "members cannot connect" do
      sign_in users(:organization_user)
      FakeTripletexApi.install

      post :create, params: { tripletex_integration: { employee_token: "secret-token" } }

      assert_redirected_to root_path
      assert_nil users(:organization_user).current_organization.tripletex_integration
    end
  end
end
