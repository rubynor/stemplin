module Workspace
  class TeamsController < WorkspaceController
    def index
      # TODO: Return all users affiliated with the organization in their respective projects
      @users = authorized_scope(User, type: :relation).all
      @organization = current_user.current_organization
    end

    def implicit_authorization_target
      User
    end
  end
end
