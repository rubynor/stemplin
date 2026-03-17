require "test_helper"
require_relative "base_test"

class Api::V1::OrganizationsControllerTest < Api::V1::BaseTest
  setup do
    @user = users(:joe)
  end

  test "index returns user organizations" do
    get api_v1_organizations_path, headers: api_headers(@user)
    assert_response :success

    orgs = json_response
    assert_kind_of Array, orgs
    assert orgs.any? { |o| o["name"] == "Company Inc" }
  end

  test "show returns organization details" do
    org = @user.organizations.first
    get api_v1_organization_path(org), headers: api_headers(@user)
    assert_response :success

    assert_equal org.name, json_response["name"]
    assert_equal org.currency, json_response["currency"]
  end

  test "show returns 404 for organization user does not belong to" do
    other_org = organizations(:organization_two)
    # joe is not in organization_two
    get api_v1_organization_path(other_org), headers: api_headers(@user)
    assert_response :not_found
  end
end
