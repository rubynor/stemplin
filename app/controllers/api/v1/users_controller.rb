module Api
  module V1
    class UsersController < BaseController
      def me
        render json: user_json(current_user)
      end

      def index
        authorize! User, to: :index?
        users = authorized_scope(User, type: :relation).onboarded.ordered_by_name
        render json: users.map { |u| user_json(u) }
      end

      def show
        user = authorized_scope(User, type: :relation).find(params[:id])
        authorize! user
        render json: user_json(user)
      end

      def regenerate_token
        current_user.regenerate_api_token
        render json: { api_token: current_user.api_token }
      end

      private

      def user_json(user)
        json = {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          name: user.name,
          locale: user.locale,
          created_at: user.created_at,
          updated_at: user.updated_at
        }

        if user == current_user
          json[:api_token] = user.api_token
          json[:current_organization] = {
            id: user.current_organization&.id,
            name: user.current_organization&.name
          }
        end

        json
      end
    end
  end
end
