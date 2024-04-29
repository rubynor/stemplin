class AssignedTasksController < ApplicationController
  before_action :authenticate_user!

  def new
    @project = Project.find(params[:project_id])
    @assigned_task = @project.assigned_tasks.build
    authorize! @assigned_task
    @tasks = authorized_scope(Task, type: :relation).where.not(id: @project.assigned_tasks.select(:task_id)).select(:id, :name)
  end

  def create
    @project = Project.find(params[:project_id])
    @assigned_task = @project.assigned_tasks.build(assigned_task_params)
    authorize! @assigned_task

    if @assigned_task.save
      flash[:notice] = t("notice.task_successfully_added_to_project")
      redirect_to edit_project_path(@project)
    else
      flash[:alert] = t("alert.task_could_not_be_added_to_the_project")
      redirect_to edit_project_path(@project)
    end
  end

  def destroy
    @project = Project.find(params[:project_id])
    @assigned_task = @project.assigned_tasks.find(params[:id])
    authorize! @assigned_task

    if @assigned_task.time_regs.count >= 1
      flash[:alert] = t("alert.cannot_remove_task_with_registered_time")
    elsif @assigned_task.destroy
      flash[:notice] = t("notice.task_succesfully_removed_from_project")
    end

    redirect_to edit_project_path(@project)
  end

  private

  def assigned_task_params
    params.require(:assigned_task).permit(:project_id, :task_id)
  end
end
