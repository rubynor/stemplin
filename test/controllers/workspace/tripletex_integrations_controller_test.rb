require "test_helper"

module Workspace
  class TripletexIntegrationsControllerTest < ActionController::TestCase
    setup do
      @admin = users(:organization_admin)
      @organization = @admin.current_organization
      sign_in @admin
    end

    teardown { FakeTripletexApi.reset }

    def connected_integration(company_id:, hourly_salary_type_id: 555)
      @organization.create_tripletex_integration!(employee_token: "old-token", company_id: company_id, hourly_salary_type_id: hourly_salary_type_id)
    end

    def link_member(user, employee_id)
      access_info = user.access_info(@organization)
      access_info.update!(tripletex_employee_id: employee_id)
      access_info
    end

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

    test "connecting sets connected_at to now" do
      FakeTripletexApi.install

      travel_to Time.zone.local(2026, 11, 11, 12) do
        post :create, params: { tripletex_integration: { employee_token: "secret-token" } }
        assert_equal Time.current, @organization.reload.tripletex_integration.connected_at
      end
    end

    test "reconnecting to the same company keeps the salary type and employee links" do
      integration = connected_integration(company_id: 42)
      access_info = link_member(users(:organization_user), 77)
      FakeTripletexApi.install

      post :create, params: { tripletex_integration: { employee_token: "new-token" } }

      assert_equal 555, integration.reload.hourly_salary_type_id
      assert_equal "new-token", integration.employee_token
      assert_equal 77, access_info.reload.tripletex_employee_id
    end

    test "reconnecting to a different company clears links and salary type and resets connected_at" do
      integration = connected_integration(company_id: 41)
      access_info = link_member(users(:organization_user), 77)
      archived = users(:organization_user).access_infos.where.not(id: access_info.id).first
      FakeTripletexApi.install

      travel_to Time.zone.local(2026, 11, 11, 12) do
        post :create, params: { tripletex_integration: { employee_token: "new-token" } }
        assert_equal Time.current, integration.reload.connected_at
      end

      assert_nil integration.hourly_salary_type_id
      assert_equal 42, integration.company_id
      assert_nil access_info.reload.tripletex_employee_id
      assert_empty @organization.access_infos.where.not(tripletex_employee_id: nil)
      assert_nil archived&.tripletex_employee_id
    end

    test "stores the chosen salary type" do
      integration = connected_integration(company_id: 42, hourly_salary_type_id: nil)

      patch :update, params: { tripletex_integration: { hourly_salary_type_id: "321" } }

      assert_redirected_to workspace_integrations_path
      assert_equal 321, integration.reload.hourly_salary_type_id
    end

    test "members cannot choose the salary type" do
      integration = connected_integration(company_id: 42)
      sign_in users(:organization_user)

      patch :update, params: { tripletex_integration: { hourly_salary_type_id: "321" } }

      assert_redirected_to root_path
      assert_equal 555, integration.reload.hourly_salary_type_id
    end

    test "disconnecting releases unsent locks and keeps employee links" do
      connected_integration(company_id: 42)
      access_info = link_member(users(:organization_user), 77)
      lock = TimeLock.new(organization: @organization, user: users(:organization_user), locked_by: @admin, period: Date.new(2026, 1, 1))
      lock.save!(validate: false)
      sent = TimeLock.new(organization: @organization, user: @admin, locked_by: @admin, period: Date.new(2026, 1, 1))
      sent.save!(validate: false)
      TimeLock.class_eval { alias_method :__sent?, :sent? }
      TimeLock.define_method(:sent?) { id == sent.id }

      begin
        delete :destroy
      ensure
        TimeLock.define_method(:sent?) { __sent? }
        TimeLock.send(:remove_method, :__sent?)
      end

      assert_nil @organization.reload.tripletex_integration
      assert_not TimeLock.exists?(lock.id)
      assert TimeLock.exists?(sent.id)
      assert_equal 77, access_info.reload.tripletex_employee_id
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
