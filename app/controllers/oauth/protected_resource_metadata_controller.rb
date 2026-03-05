# frozen_string_literal: true

module Oauth
  class ProtectedResourceMetadataController < ActionController::Base
    def show
      render json: {
        resource: request.base_url,
        authorization_servers: [ request.base_url ],
        bearer_methods_supported: [ "header" ],
        scopes_supported: [ "mcp" ]
      }
    end
  end
end
