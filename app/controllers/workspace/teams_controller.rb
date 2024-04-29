module Workspace
  class TeamsController < WorkspaceController
    def index
      @users = authorized_scope(User, type: :relation).all
    end

    def new_modal
      @user = User.new
      @roles = AccessInfo.allowed_organization_roles
    end

    def create
      ActiveRecord::Base.transaction do
        @user = User.new(team_member_params.except(:role).merge(is_verified: false))
        @user.save!
        AccessInfo.create!(user: @user, organization: current_user.current_organization, role: AccessInfo.roles[team_member_params[:role]])
      end

      render turbo_stream: [
        turbo_flash(type: :success, data: t("notice.user_added_to_the_organization")),
        turbo_stream.append(:organization_users, partial: "workspace/teams/user", locals: { user: @user }),
        turbo_stream.action(:remove_modal, :modal)
      ]
    rescue => e
      @roles = AccessInfo.allowed_organization_roles
      render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/teams/form", locals: { user: @user, roles: @roles })
    end

    def implicit_authorization_target
      User
    end

    private

    def team_member_params
      params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation, :role)
    end
  end
end
