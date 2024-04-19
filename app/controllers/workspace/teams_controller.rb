module Workspace
  class TeamsController < WorkspaceController
    def index
      # TODO: Return all users affiliated with the organization in their respective projects
    end

    def implicit_authorization_target
      User
    end
  end
end
