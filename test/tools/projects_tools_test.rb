require_relative "tool_test_helper"

class ListProjectsToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
  end

  test "returns projects for organization" do
    result = call_tool(ListProjectsTool, user: @admin, organization: @org)
    projects = parse_result(result)

    assert_kind_of Array, projects
    assert projects.any? { |p| p["name"] == "E Corp CRM" }
    projects.each do |p|
      assert p.key?("id")
      assert p.key?("name")
      assert p.key?("client_id")
      assert p.key?("client_name")
      assert p.key?("billable")
      assert p.key?("rate")
      assert p.key?("rate_currency")
      assert p.key?("created_at")
      assert p.key?("updated_at")
    end
  end

  test "returns error for non-admin user" do
    joe = users(:joe)
    result = call_tool(ListProjectsTool, user: joe, organization: @org)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end

  test "returns error without auth" do
    result = call_tool(ListProjectsTool, organization: @org)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class ShowProjectToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
    @project = projects(:project_1)
  end

  test "returns project details with assigned tasks" do
    result = call_tool(ShowProjectTool, user: @admin, organization: @org, id: @project.id)
    project = parse_result(result)

    assert_equal @project.id, project["id"]
    assert_equal "E Corp CRM", project["name"]
    assert_equal @project.client_id, project["client_id"]
    assert_equal "E Corp", project["client_name"]
    assert project.key?("assigned_tasks")
    assert_kind_of Array, project["assigned_tasks"]

    if project["assigned_tasks"].any?
      at = project["assigned_tasks"].first
      assert at.key?("id")
      assert at.key?("task_id")
      assert at.key?("task_name")
      assert at.key?("rate")
      assert at.key?("rate_currency")
    end
  end

  test "returns error for non-admin user" do
    joe = users(:joe)
    result = call_tool(ShowProjectTool, user: joe, organization: @org, id: @project.id)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class CreateProjectToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
    @client = clients(:e_corp)
  end

  test "creates a project" do
    result = call_tool(CreateProjectTool, user: @admin, organization: @org,
      name: "New Project", client_id: @client.id)
    project = parse_result(result)

    assert_equal "New Project", project["name"]
    assert_equal @client.id, project["client_id"]
    assert_equal "E Corp", project["client_name"]
    assert project.key?("id")
    assert project.key?("assigned_tasks")
  end

  test "creates a billable project with rate" do
    result = call_tool(CreateProjectTool, user: @admin, organization: @org,
      name: "Billable Project", client_id: @client.id, billable: true, rate_currency: "1,50")
    project = parse_result(result)

    assert_equal true, project["billable"]
    assert_equal 150, project["rate"]
  end

  test "returns error for non-admin user" do
    joe = users(:joe)
    result = call_tool(CreateProjectTool, user: joe, organization: @org,
      name: "Forbidden Project", client_id: @client.id)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end

  test "returns error for invalid name" do
    result = call_tool(CreateProjectTool, user: @admin, organization: @org,
      name: "X", client_id: @client.id)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class UpdateProjectToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
    @project = projects(:project_1)
  end

  test "updates a project name" do
    result = call_tool(UpdateProjectTool, user: @admin, organization: @org,
      id: @project.id, name: "Updated CRM")
    project = parse_result(result)

    assert_equal @project.id, project["id"]
    assert_equal "Updated CRM", project["name"]
    assert project.key?("assigned_tasks")
  end

  test "returns error for non-admin user" do
    joe = users(:joe)
    result = call_tool(UpdateProjectTool, user: joe, organization: @org,
      id: @project.id, name: "Nope")
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class DeleteProjectToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
    @project = projects(:to_be_deleted)
  end

  test "soft deletes a project" do
    result = call_tool(DeleteProjectTool, user: @admin, organization: @org, id: @project.id)
    parsed = parse_result(result)

    assert_equal "deleted", parsed["status"]
    assert_equal @project.id, parsed["id"]
    assert @project.reload.discarded?
  end

  test "returns error for non-admin user" do
    joe = users(:joe)
    result = call_tool(DeleteProjectTool, user: joe, organization: @org, id: @project.id)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end
