require_relative "tool_test_helper"

class ListTimeRegsToolTest < ToolTestCase
  setup do
    @joe = users(:joe)
    @org = organizations(:organization_one)
  end

  test "returns time regs for current user" do
    result = call_tool(ListTimeRegsTool, user: @joe, organization: @org)
    parsed = parse_result(result)

    assert parsed.key?("time_regs")
    assert parsed.key?("pagination")
    assert parsed["time_regs"].any?

    tr = parsed["time_regs"].first
    assert tr.key?("id")
    assert tr.key?("notes")
    assert tr.key?("minutes")
    assert tr.key?("date_worked")
    assert tr.key?("assigned_task_id")
    assert tr.key?("user_id")
    assert tr.key?("current_minutes")
    assert tr.key?("active")
    assert tr.key?("task_name")
    assert tr.key?("project_id")
    assert tr.key?("project_name")
    assert tr.key?("client_name")

    # All time regs should belong to joe
    parsed["time_regs"].each do |reg|
      assert_equal @joe.id, reg["user_id"]
    end
  end

  test "filters by date" do
    result = call_tool(ListTimeRegsTool, user: @joe, organization: @org, date: Date.today.to_s)
    parsed = parse_result(result)

    parsed["time_regs"].each do |tr|
      assert_equal Date.today.to_s, tr["date_worked"]
    end
  end

  test "filters by date range" do
    start_date = (Date.today - 3).to_s
    end_date = Date.today.to_s
    result = call_tool(ListTimeRegsTool, user: @joe, organization: @org, start_date: start_date, end_date: end_date)
    parsed = parse_result(result)

    assert parsed["time_regs"].any?
  end

  test "returns pagination info" do
    result = call_tool(ListTimeRegsTool, user: @joe, organization: @org, per_page: 2)
    parsed = parse_result(result)

    assert parsed["pagination"].key?("current_page")
    assert parsed["pagination"].key?("total_pages")
    assert parsed["pagination"].key?("total_count")
    assert_equal 1, parsed["pagination"]["current_page"]
    assert parsed["time_regs"].size <= 2
  end

  test "returns error without auth" do
    result = call_tool(ListTimeRegsTool, organization: @org)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class ShowTimeRegToolTest < ToolTestCase
  setup do
    @joe = users(:joe)
    @org = organizations(:organization_one)
    @time_reg = time_regs(:time_reg_1)
  end

  test "returns time reg details" do
    result = call_tool(ShowTimeRegTool, user: @joe, organization: @org, id: @time_reg.id)
    parsed = parse_result(result)

    assert_equal @time_reg.id, parsed["id"]
    assert_equal @joe.id, parsed["user_id"]
    assert_equal @time_reg.minutes, parsed["minutes"]
  end

  test "returns error for another users time reg" do
    ron_time_reg = time_regs(:time_reg_2)
    result = call_tool(ShowTimeRegTool, user: @joe, organization: @org, id: ron_time_reg.id)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class CreateTimeRegToolTest < ToolTestCase
  setup do
    @joe = users(:joe)
    @org = organizations(:organization_one)
    @assigned_task = assigned_task(:task_1)
  end

  test "creates a time reg" do
    result = call_tool(CreateTimeRegTool, user: @joe, organization: @org,
      assigned_task_id: @assigned_task.id, minutes: 60, date_worked: Date.today.to_s, notes: "Test work")
    parsed = parse_result(result)

    assert parsed.key?("id")
    assert_equal 60, parsed["minutes"]
    assert_equal @joe.id, parsed["user_id"]
    assert_equal "Test work", parsed["notes"]
    assert_equal @assigned_task.id, parsed["assigned_task_id"]
  end

  test "returns error for invalid minutes" do
    result = call_tool(CreateTimeRegTool, user: @joe, organization: @org,
      assigned_task_id: @assigned_task.id, minutes: 2000, date_worked: Date.today.to_s)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end

  test "returns error without auth" do
    result = call_tool(CreateTimeRegTool, organization: @org,
      assigned_task_id: @assigned_task.id, minutes: 60, date_worked: Date.today.to_s)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class UpdateTimeRegToolTest < ToolTestCase
  setup do
    @joe = users(:joe)
    @org = organizations(:organization_one)
    @time_reg = time_regs(:time_reg_1)
  end

  test "updates a time reg" do
    result = call_tool(UpdateTimeRegTool, user: @joe, organization: @org,
      id: @time_reg.id, minutes: 90, notes: "Updated notes")
    parsed = parse_result(result)

    assert_equal @time_reg.id, parsed["id"]
    assert_equal 90, parsed["minutes"]
    assert_equal "Updated notes", parsed["notes"]
  end

  test "returns error for another users time reg" do
    ron_time_reg = time_regs(:time_reg_2)
    result = call_tool(UpdateTimeRegTool, user: @joe, organization: @org,
      id: ron_time_reg.id, minutes: 90)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class DeleteTimeRegToolTest < ToolTestCase
  setup do
    @joe = users(:joe)
    @org = organizations(:organization_one)
    @time_reg = time_regs(:time_reg_5)
  end

  test "soft deletes a time reg" do
    result = call_tool(DeleteTimeRegTool, user: @joe, organization: @org, id: @time_reg.id)
    parsed = parse_result(result)

    assert_equal "deleted", parsed["status"]
    assert_equal @time_reg.id, parsed["id"]
    assert @time_reg.reload.discarded?
  end

  test "returns error for another users time reg" do
    ron_time_reg = time_regs(:time_reg_2)
    result = call_tool(DeleteTimeRegTool, user: @joe, organization: @org, id: ron_time_reg.id)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end
