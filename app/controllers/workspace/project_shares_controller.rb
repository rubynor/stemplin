module Workspace
  class ProjectSharesController < WorkspaceController
    before_action :set_project
    before_action :set_project_share, only: %i[update destroy]

    def index
      authorize! ProjectShare
      @project_shares = authorized_scope(ProjectShare, type: :relation)
        .where(project: @project)
        .includes(:organization)
    end

    def update
      authorize! @project_share
      if @project_share.update(project_share_params)
        redirect_to workspace_project_path(@project), notice: t("notice.project_share_rates_updated")
      else
        redirect_to workspace_project_path(@project), alert: t("alert.unable_to_proceed")
      end
    end

    def destroy
      authorize! @project_share
      DisconnectProjectShareService.new(project_share: @project_share).call

      if owner_org?
        redirect_to workspace_project_path(@project), notice: t("notice.project_share_disconnected")
      else
        redirect_to workspace_projects_path, notice: t("notice.project_share_disconnected")
      end
    end

    private

    def set_project
      @project = authorized_scope(Project, type: :relation).find(params[:project_id])
    end

    def set_project_share
      @project_share = authorized_scope(ProjectShare, type: :relation).find(params[:id])
    end

    def project_share_params
      params.require(:project_share).permit(
        :rate_currency,
        project_share_task_rates_attributes: [ :id, :rate_currency ]
      )
    end

    def owner_org?
      @project.owning_organization == current_user.current_organization
    end
  end
end
