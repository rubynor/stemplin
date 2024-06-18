module Workspace
  module TeamScoped
    extend ActiveSupport::Concern

    included do
      private

      def team_member_params
        params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation, :role)
      end

      def create_access_info_for(user)
        authorized_scope(AccessInfo, type: :relation).create!(
          user: user,
          organization: current_user.current_organization,
          role: AccessInfo.roles[team_member_params[:role]]
        )
      end

      def handle_success(user:, message:)
        render turbo_stream: [
          turbo_flash(type: :success, data: message),
          turbo_stream.append(:organization_users, partial: "workspace/teams/user", locals: { user: user }),
          turbo_stream.action(:remove_modal, :modal)
        ]
      end

      def new_user_info
        team_member_params.except(:role).merge(is_verified: false)
      end

      def populate_form_for(user)
        @roles = AccessInfo.allowed_organization_roles
        render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/teams/form", locals: { user: user, roles: @roles })
      end
    end
  end
end
