require "test_helper"

module Workspace
  class IntegrationsControllerTest < ActionController::TestCase
    setup { Rails.cache.clear }
    teardown { FakeTripletexApi.reset }

    test "admin sees the integrations" do
      admin = users(:organization_admin)
      sign_in admin
      admin.current_organization.create_tripletex_integration!(employee_token: "secret-token", company_name: "Firma AS")

      get :show

      assert_response :success
      assert_includes response.body, "Firma AS"
    end

    test "lists the salary types and preselects Timelønn when none is stored" do
      admin = users(:organization_admin)
      sign_in admin
      admin.current_organization.create_tripletex_integration!(employee_token: "secret-token", company_name: "Firma AS")
      FakeTripletexApi.install(FakeTripletexApi.new(salary_types: [
        { "id" => 1, "number" => "2000", "name" => "Fastlønn" },
        { "id" => 2, "number" => "2001", "name" => "Timelønn" },
        { "id" => 3, "number" => "2002", "name" => "Sykelønn - timelønn" }
      ]))

      get :show

      assert_select "select[name='tripletex_integration[hourly_salary_type_id]'] option", count: 4
      assert_select "option[selected]", count: 1
      assert_select "option[selected][value='2']", text: /Timelønn/
    end

    test "keeps the stored salary type and shows the error when the list cannot be loaded" do
      admin = users(:organization_admin)
      sign_in admin
      admin.current_organization.create_tripletex_integration!(employee_token: "secret-token", company_name: "Firma AS", hourly_salary_type_id: 99)
      FakeTripletexApi.install(FakeTripletexApi.new(error: "Tripletex er nede"))

      get :show

      assert_response :success
      assert_select "option[selected][value='99']", text: "#99"
      assert_includes response.body, "Tripletex er nede"
    end

    test "members cannot see the integrations" do
      sign_in users(:organization_user)
      get :show
      assert_redirected_to root_path
    end
  end
end
