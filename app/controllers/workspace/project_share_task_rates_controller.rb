module Workspace
  class ProjectShareTaskRatesController < WorkspaceController
    before_action :set_project
    before_action :set_project_share
    before_action :set_task_rate, only: :update

    def create
      @task_rate = @project_share.project_share_task_rates.new(task_rate_params)
      authorize! @task_rate

      if @task_rate.save
        redirect_to workspace_project_path(@project), notice: t("notice.rates_updated")
      else
        redirect_to workspace_project_path(@project), alert: t("alert.unable_to_proceed")
      end
    end

    def update
      authorize! @task_rate

      if @task_rate.update(task_rate_params)
        redirect_to workspace_project_path(@project), notice: t("notice.rates_updated")
      else
        redirect_to workspace_project_path(@project), alert: t("alert.unable_to_proceed")
      end
    end

    private

    def set_project
      @project = authorized_scope(Project, type: :relation).find(params[:project_id])
    end

    def set_project_share
      @project_share = authorized_scope(ProjectShare, type: :relation).find(params[:project_share_id])
    end

    def set_task_rate
      @task_rate = authorized_scope(ProjectShareTaskRate, type: :relation).find(params[:id])
    end

    def task_rate_params
      params.require(:project_share_task_rate).permit(:assigned_task_id, :rate_currency)
    end
  end
end
