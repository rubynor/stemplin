module Api
  module V1
    class ApiTokensController < BaseController
      def update
        current_user.regenerate_api_token
        render json: { api_token: current_user.api_token }
      end
    end
  end
end
