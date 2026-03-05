require_relative "tool_test_helper"

class ListOrganizationsToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
  end

  test "returns user organizations" do
    result = call_tool(ListOrganizationsTool, user: @admin)
    orgs = parse_result(result)
    assert_kind_of Array, orgs
    assert orgs.any? { |o| o.key?("id") && o.key?("name") }
  end

  test "returns error without auth" do
    result = call_tool(ListOrganizationsTool)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end
