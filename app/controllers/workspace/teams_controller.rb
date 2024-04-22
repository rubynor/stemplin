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
    end

    def implicit_authorization_target
      User
    end

    def delete_confirmation
    end

    private

    def team_member_params
      params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation, :role)
    end
  end
end
