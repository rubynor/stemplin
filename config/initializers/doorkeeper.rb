# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record

  resource_owner_authenticator do
    current_user || warden.authenticate!(scope: :user)
  end

  # MCP clients are public (no client_secret), so require PKCE
  force_pkce
  pkce_code_challenge_methods %w[S256]

  # Only authorization code flow (most secure for interactive clients)
  grant_flows %w[authorization_code]

  # Hash tokens in the database so a DB leak doesn't expose live tokens
  hash_token_secrets using: "::Doorkeeper::SecretStoring::Sha256Hash"

  access_token_expires_in 1.hour

  use_refresh_token

  default_scopes :mcp

  base_controller "DoorkeeperBaseController"

  # Allow non-HTTPS redirect URIs in development (MCP clients use localhost)
  force_ssl_in_redirect_uri { |uri| !Rails.env.local? }

  # Allow any redirect URI scheme for MCP clients (e.g. http://localhost)
  allow_blank_redirect_uri false

  # Only allow redirect URIs pointing to trusted hosts
  forbid_redirect_uri do |uri|
    allowed_hosts = %w[localhost 127.0.0.1]
    allowed_domains = %w[claude.ai claude.com]

    host = uri.host.to_s.downcase
    next false if allowed_hosts.include?(host)
    next false if allowed_domains.any? { |domain| host == domain || host.end_with?(".#{domain}") }

    true
  end
end
