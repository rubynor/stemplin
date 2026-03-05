require "fast_mcp"
require_relative "../../app/middleware/mcp_oauth_middleware"

FastMcp.mount_in_rails(
  Rails.application,
  name: "stemplin",
  version: "1.0.0",
  path_prefix: "/mcp",
  authenticate: false
) do |server|
  Rails.application.config.after_initialize do
    server.register_tools(*ApplicationTool.descendants)
  end
end

Rails.application.config.middleware.insert_before FastMcp::Transports::RackTransport, McpOauthMiddleware
