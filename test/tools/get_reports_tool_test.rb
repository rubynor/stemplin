require_relative "tool_test_helper"

class GetReportsToolTest < ToolTestCase
  setup do
    @joe = users(:joe)
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
  end

  test "returns report data for date range" do
    start_date = (Date.today - 30).to_s
    end_date = Date.today.to_s
    result = call_tool(GetReportsTool, user: @joe, organization: @org,
      start_date: start_date, end_date: end_date)
    parsed = parse_result(result)

    assert parsed.key?("total_minutes")
    assert parsed.key?("total_entries")
    assert parsed.key?("by_project")
    assert parsed.key?("by_user")
    assert parsed["total_minutes"] >= 0
    assert parsed["total_entries"] >= 0
  end

  test "admin sees all org data in reports" do
    start_date = (Date.today - 30).to_s
    end_date = Date.today.to_s
    result = call_tool(GetReportsTool, user: @admin, organization: @org,
      start_date: start_date, end_date: end_date)
    parsed = parse_result(result)

    assert parsed["total_entries"] > 0
    assert parsed["by_project"].any?
    assert parsed["by_user"].any?

    parsed["by_project"].each do |row|
      assert row.key?("project_id")
      assert row.key?("project_name")
      assert row.key?("client_name")
      assert row.key?("total_minutes")
      assert row.key?("total_entries")
    end

    parsed["by_user"].each do |row|
      assert row.key?("user_id")
      assert row.key?("user_name")
      assert row.key?("total_minutes")
      assert row.key?("total_entries")
    end
  end

  test "filters by project_ids" do
    project = projects(:project_1)
    start_date = (Date.today - 30).to_s
    end_date = Date.today.to_s
    result = call_tool(GetReportsTool, user: @admin, organization: @org,
      start_date: start_date, end_date: end_date, project_ids: project.id.to_s)
    parsed = parse_result(result)

    assert parsed["total_entries"] > 0
    parsed["by_project"].each do |row|
      assert_equal project.id, row["project_id"]
    end
  end

  test "returns error without auth" do
    result = call_tool(GetReportsTool, organization: @org,
      start_date: Date.today.to_s, end_date: Date.today.to_s)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end
