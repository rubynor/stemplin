require_relative "tool_test_helper"

class ToggleTimerToolTest < ToolTestCase
  setup do
    @joe = users(:joe)
    @org = organizations(:organization_one)
    @time_reg = time_regs(:time_reg_1)
  end

  test "starts a timer on a time reg" do
    assert_not @time_reg.active?

    result = call_tool(ToggleTimerTool, user: @joe, organization: @org, time_reg_id: @time_reg.id)
    parsed = parse_result(result)

    assert_equal @time_reg.id, parsed["id"]
    assert parsed["active"]
    assert_not_nil parsed["start_time"]
  end

  test "stops an active timer" do
    # Start the timer first
    @time_reg.toggle_active
    assert @time_reg.reload.active?

    result = call_tool(ToggleTimerTool, user: @joe, organization: @org, time_reg_id: @time_reg.id)
    parsed = parse_result(result)

    assert_equal @time_reg.id, parsed["id"]
    assert_not parsed["active"]
    assert_nil parsed["start_time"]
  end

  test "returns error for another users time reg" do
    ron_time_reg = time_regs(:time_reg_2)
    result = call_tool(ToggleTimerTool, user: @joe, organization: @org, time_reg_id: ron_time_reg.id)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end

  test "returns error without auth" do
    result = call_tool(ToggleTimerTool, organization: @org, time_reg_id: @time_reg.id)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end
