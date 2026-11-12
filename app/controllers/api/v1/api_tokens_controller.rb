module Api
  module V1
    class ApiTokensController < BaseController
      # Replaces the secret of the token making the request. The user's other
      # tokens are left alone.
      def update
        authorize! current_api_token
        render json: { api_token: current_api_token.regenerate! }
      end
    end
  end
end
