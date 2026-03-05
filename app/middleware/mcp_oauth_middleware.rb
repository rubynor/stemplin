# frozen_string_literal: true

class McpOauthMiddleware
  MCP_PATH_PREFIX = "/mcp"

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    unless request.path.start_with?(MCP_PATH_PREFIX)
      return @app.call(env)
    end

    token_string = extract_bearer_token(env)

    if token_string.blank?
      return unauthorized_response(request)
    end

    access_token = Doorkeeper::AccessToken.by_token(token_string)

    if access_token.nil? || access_token.revoked? || access_token.expired? || !access_token.acceptable?([ :mcp ])
      return unauthorized_response(request)
    end

    # Strip any externally-set header to prevent spoofing, then set the signed authenticated user ID.
    # fast-mcp passes all HTTP_* env vars as headers to tools.
    env.delete("HTTP_X_MCP_OAUTH_USER_ID")
    env["HTTP_X_MCP_OAUTH_USER_ID"] = self.class.message_verifier.generate(
      access_token.resource_owner_id, purpose: "mcp_oauth_user_id"
    )

    @app.call(env)
  end

  def self.message_verifier
    @message_verifier ||= ActiveSupport::MessageVerifier.new(
      Rails.application.secret_key_base, digest: "SHA256"
    )
  end

  private

  def extract_bearer_token(env)
    auth_header = env["HTTP_AUTHORIZATION"]
    return nil if auth_header.blank?

    match = auth_header.match(/\ABearer\s+(.+)\z/i)
    match&.[](1)
  end

  def unauthorized_response(request)
    resource_metadata_url = "#{request.base_url}/.well-known/oauth-protected-resource"

    [
      401,
      {
        "WWW-Authenticate" => "Bearer resource_metadata=\"#{resource_metadata_url}\"",
        "Content-Type" => "application/json"
      },
      [ '{"error":"unauthorized","error_description":"Valid OAuth access token required"}' ]
    ]
  end
end
