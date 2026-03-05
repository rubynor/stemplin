# frozen_string_literal: true

module Oauth
  class DynamicRegistrationController < ActionController::Base
    skip_forgery_protection

    MAX_REDIRECT_URIS = 5
    MAX_REDIRECT_URI_LENGTH = 2048
    MAX_CLIENT_NAME_LENGTH = 255
    MAX_APPLICATIONS_PER_IP = 50

    def create
      redirect_uris = params[:redirect_uris]

      if redirect_uris.blank? || !redirect_uris.is_a?(Array) || redirect_uris.empty?
        render json: { error: "invalid_client_metadata", error_description: "redirect_uris is required" }, status: :bad_request
        return
      end

      if redirect_uris.length > MAX_REDIRECT_URIS
        render json: { error: "invalid_client_metadata", error_description: "too many redirect_uris (max #{MAX_REDIRECT_URIS})" }, status: :bad_request
        return
      end

      if redirect_uris.any? { |uri| uri.to_s.length > MAX_REDIRECT_URI_LENGTH }
        render json: { error: "invalid_client_metadata", error_description: "redirect_uri exceeds max length of #{MAX_REDIRECT_URI_LENGTH}" }, status: :bad_request
        return
      end

      ip = request.remote_ip
      if Doorkeeper::Application.where(registration_ip: ip).count >= MAX_APPLICATIONS_PER_IP
        render json: { error: "too_many_registrations", error_description: "registration limit reached for this IP" }, status: :forbidden
        return
      end

      client_name = (params[:client_name].presence || "MCP Client").truncate(MAX_CLIENT_NAME_LENGTH)

      application = Doorkeeper::Application.new(
        name: client_name,
        redirect_uri: redirect_uris.join("\n"),
        scopes: "mcp",
        confidential: false,
        registration_ip: ip
      )

      if application.save
        render json: {
          client_id: application.uid,
          client_name: application.name,
          redirect_uris: redirect_uris,
          grant_types: [ "authorization_code" ],
          response_types: [ "code" ],
          token_endpoint_auth_method: "none",
          scope: "mcp"
        }, status: :created
      else
        render json: { error: "invalid_client_metadata", error_description: application.errors.full_messages.join(", ") }, status: :bad_request
      end
    end
  end
end
