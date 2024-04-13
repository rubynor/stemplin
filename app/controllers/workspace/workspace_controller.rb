module Workspace
  class WorkspaceController < ApplicationController
    before_action :authorize!

    layout -> do
      "workspace"
    end

    def index
    end
  end
end
