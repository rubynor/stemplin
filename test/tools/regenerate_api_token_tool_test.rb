require_relative "tool_test_helper"

class RegenerateApiTokenToolTest < ToolTestCase
  setup do
    @joe = users(:joe)
  end

  test "regenerates the api token" do
    result = call_tool(RegenerateApiTokenTool, user: @joe)
    parsed = parse_result(result)

    assert parsed.key?("api_token")
    new_token = parsed["api_token"]
    assert_equal 24, new_token.length

    # Verify the new token can authenticate
    assert User.find_by_api_token(new_token)
  end

  test "returns error without auth" do
    result = call_tool(RegenerateApiTokenTool)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end
