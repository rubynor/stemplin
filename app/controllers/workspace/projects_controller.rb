module Workspace
  class ProjectsController < WorkspaceController
    def index
      @projects = current_user.projects
    end

    def import_modal
    end
  end
end
