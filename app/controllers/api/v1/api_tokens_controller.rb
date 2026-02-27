module Api
  module V1
    class ApiTokensController < BaseController
      def update
        token = current_user.regenerate_api_token!
        render json: { api_token: token }
      end
    end
  end
end
