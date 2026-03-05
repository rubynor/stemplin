module Workspace
  class WorkspaceController < ApplicationController
    layout -> do
      "workspace"
    end

    rescue_from ActiveRecord::RecordNotFound do |ex|
      redirect_to root_path
    end

    def index
    end
  end
end
