require_relative "tool_test_helper"

class ListTasksToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
  end

  test "returns tasks for organization" do
    result = call_tool(ListTasksTool, user: @admin, organization: @org)
    tasks = parse_result(result)

    assert_kind_of Array, tasks
    assert tasks.any? { |t| t["name"] == "Debug" }
    tasks.each do |t|
      assert t.key?("id")
      assert t.key?("name")
      assert t.key?("organization_id")
      assert t.key?("created_at")
      assert t.key?("updated_at")
    end
  end

  test "does not return tasks from other organizations" do
    result = call_tool(ListTasksTool, user: @admin, organization: @org)
    tasks = parse_result(result)

    org_two_task_names = [ "login" ] # from fixtures - login belongs to org_two
    tasks.each do |t|
      assert_not_includes org_two_task_names, t["name"]
    end
  end

  test "returns error without auth" do
    result = call_tool(ListTasksTool, organization: @org)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class ShowTaskToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
    @task = tasks(:debug)
  end

  test "returns task details" do
    result = call_tool(ShowTaskTool, user: @admin, organization: @org, id: @task.id)
    task = parse_result(result)

    assert_equal @task.id, task["id"]
    assert_equal "Debug", task["name"]
    assert_equal @org.id, task["organization_id"]
  end

  test "returns error for task in another organization" do
    other_task = tasks(:login) # belongs to organization_two
    result = call_tool(ShowTaskTool, user: @admin, organization: @org, id: other_task.id)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end

  test "returns error without auth" do
    result = call_tool(ShowTaskTool, id: @task.id)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end
