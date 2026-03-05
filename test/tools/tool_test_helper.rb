require "test_helper"

class ToolTestCase < ActiveSupport::TestCase
  fixtures :all

  private

  def call_tool(tool_class, user: nil, organization: nil, **args)
    headers = {}
    if user
      headers["x-mcp-oauth-user-id"] = McpOauthMiddleware.message_verifier.generate(
        user.id, purpose: "mcp_oauth_user_id"
      )
    end
    args[:organization_id] = organization.id if organization

    tool = tool_class.new(headers: headers)
    result, _meta = tool.call_with_schema_validation!(**args)
    result
  end

  def parse_result(result)
    JSON.parse(result)
  end
end
