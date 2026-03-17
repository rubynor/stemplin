require_relative "tool_test_helper"

class ListUsersToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
  end

  test "returns users for organization" do
    result = call_tool(ListUsersTool, user: @admin, organization: @org)
    users = parse_result(result)

    assert_kind_of Array, users
    assert users.any?
    users.each do |u|
      assert u.key?("id")
      assert u.key?("email")
      assert u.key?("first_name")
      assert u.key?("last_name")
      assert u.key?("locale")
      assert u.key?("name")
      assert u.key?("created_at")
      assert u.key?("updated_at")
    end
  end

  test "returns error without auth" do
    result = call_tool(ListUsersTool, organization: @org)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class ShowUserToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @joe = users(:joe)
    @org = organizations(:organization_one)
  end

  test "admin can show another user" do
    result = call_tool(ShowUserTool, user: @admin, organization: @org, id: @joe.id)
    parsed = parse_result(result)

    assert_equal @joe.id, parsed["id"]
    assert_equal @joe.email, parsed["email"]
    assert_equal @joe.first_name, parsed["first_name"]
    assert_equal @joe.last_name, parsed["last_name"]
  end

  test "user can show themselves" do
    result = call_tool(ShowUserTool, user: @joe, organization: @org, id: @joe.id)
    parsed = parse_result(result)

    assert_equal @joe.id, parsed["id"]
  end

  test "non-admin cannot show another user" do
    ron = users(:ron)
    result = call_tool(ShowUserTool, user: @joe, organization: @org, id: ron.id)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class GetCurrentUserToolTest < ToolTestCase
  setup do
    @joe = users(:joe)
  end

  test "returns current user info" do
    result = call_tool(GetCurrentUserTool, user: @joe)
    parsed = parse_result(result)

    assert_equal @joe.id, parsed["id"]
    assert_equal @joe.email, parsed["email"]
    assert_equal @joe.first_name, parsed["first_name"]
    assert_equal @joe.last_name, parsed["last_name"]
    assert_equal @joe.name, parsed["name"]
    assert parsed.key?("has_api_token")
    assert parsed.key?("current_organization")
  end

  test "includes current organization" do
    result = call_tool(GetCurrentUserTool, user: @joe)
    parsed = parse_result(result)

    org = parsed["current_organization"]
    assert_not_nil org
    assert org.key?("id")
    assert org.key?("name")
  end

  test "returns error without auth" do
    result = call_tool(GetCurrentUserTool)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end
