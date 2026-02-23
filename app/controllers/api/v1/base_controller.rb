module Api
  module V1
    class BaseController < ActionController::API
      include ActionPolicy::Controller
      include Pagy::Backend

      authorize :user, through: :current_user

      before_action :authenticate_api_user!

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionPolicy::Unauthorized, with: :forbidden

      private

      def authenticate_api_user!
        token = request.headers["Authorization"]&.remove("Bearer ")
        @current_user = User.find_by(api_token: token) if token.present?

        render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
      end

      def current_user
        @current_user
      end

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: { error: exception.record.errors.full_messages }, status: :unprocessable_entity
      end

      def forbidden
        render json: { error: "Forbidden" }, status: :forbidden
      end

      def pagy_metadata(pagy)
        { current_page: pagy.page, total_pages: pagy.pages, total_count: pagy.count }
      end
    end
  end
end
