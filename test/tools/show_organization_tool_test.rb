require_relative "tool_test_helper"

class ShowOrganizationToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
  end

  test "returns organization details" do
    result = call_tool(ShowOrganizationTool, user: @admin, id: @org.id)
    org = parse_result(result)

    assert_equal @org.id, org["id"]
    assert_equal @org.name, org["name"]
    assert_equal @org.currency, org["currency"]
    assert org.key?("created_at")
    assert org.key?("updated_at")
  end

  test "returns error for organization user does not belong to" do
    other_org = organizations(:organization_three)
    # organization_admin belongs to org_three but let's use joe who only belongs to org_one
    joe = users(:joe)
    result = call_tool(ShowOrganizationTool, user: joe, id: other_org.id)
    parsed = parse_result(result)

    assert parsed.key?("error")
  end

  test "returns error without auth" do
    result = call_tool(ShowOrganizationTool, id: @org.id)
    parsed = parse_result(result)

    assert parsed.key?("error")
  end
end
