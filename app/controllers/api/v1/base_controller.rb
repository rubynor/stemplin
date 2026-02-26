module Api
  module V1
    class BaseController < ActionController::API
      include ActionPolicy::Controller
      include Pagy::Backend

      authorize :user, through: :current_user

      before_action :authenticate_api_user!
      before_action :resolve_organization

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionPolicy::Unauthorized, with: :forbidden

      private

      def authenticate_api_user!
        token = request.headers["Authorization"]&.delete_prefix("Bearer ")
        @current_user = User.find_by(api_token: token) if token.present?

        render json: { errors: [ "Unauthorized" ] }, status: :unauthorized unless @current_user
      end

      def resolve_organization
        org_id = request.headers["X-Organization-Id"]
        return unless org_id.present?

        resolved_access_info = current_user.access_infos.find_by!(organization_id: org_id)

        current_user.define_singleton_method(:access_info) do |organization = nil|
          return access_infos.find_by(organization: organization) if organization
          resolved_access_info
        end
      end

      def current_user
        @current_user
      end

      def not_found
        render json: { errors: [ "Not found" ] }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
      end

      def forbidden
        render json: { errors: [ "Forbidden" ] }, status: :forbidden
      end
    end
  end
end
