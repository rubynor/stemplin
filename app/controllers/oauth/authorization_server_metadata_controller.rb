# frozen_string_literal: true

module Oauth
  class AuthorizationServerMetadataController < ActionController::Base
    def show
      render json: {
        issuer: request.base_url,
        authorization_endpoint: "#{request.base_url}/oauth/authorize",
        token_endpoint: "#{request.base_url}/oauth/token",
        registration_endpoint: "#{request.base_url}/oauth/register",
        response_types_supported: [ "code" ],
        grant_types_supported: [ "authorization_code" ],
        token_endpoint_auth_methods_supported: [ "none" ],
        code_challenge_methods_supported: [ "S256" ],
        scopes_supported: [ "mcp" ]
      }
    end
  end
end
