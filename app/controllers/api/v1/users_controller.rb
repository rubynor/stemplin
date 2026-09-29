module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: %i[show]

      def me
        @user = current_user
      end

      def index
        authorize!
        @users = authorized_scope(User, type: :relation).unarchived_in(current_user.current_organization).onboarded.ordered_by_name
      end

      def show
        authorize! @user
      end

      private

      def set_user
        @user = authorized_scope(User, type: :relation).find(params[:id])
      end
    end
  end
end
