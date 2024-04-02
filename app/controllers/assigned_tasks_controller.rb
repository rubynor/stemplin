class AssignedTasksController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_membership
  before_action :authorize!

  def new
    @project = authorized_scope(Project, type: :relation).find(params[:project_id])
    @assigned_task = @project.assigned_tasks.build
    @tasks = authorized_scope(Task, type: :relation).where.not(id: @project.assigned_tasks.select(:task_id)).select(:id, :name)
  end

  def create
    @project = authorized_scope(Project, type: :relation).find(params[:project_id])
    @assigned_task = @project.assigned_tasks.build(assigned_task_params)

    if @assigned_task.save
      flash[:notice] = "Task successfully added to project"
      redirect_to edit_project_path(@project)
    else
      flash[:alert] = "Task could not be added to the project"
      redirect_to edit_project_path(@project)
    end
  end

  def destroy
    @project = authorized_scope(Project, type: :relation).find(params[:project_id])
    @assigned_task = @project.assigned_tasks.find(params[:id])

    if @assigned_task.time_regs.count >= 1
      flash[:alert] = "Cannot remove task with registered time"
    elsif @assigned_task.destroy
      flash[:notice] = "Task succesfully removed from project"
    end

    redirect_to edit_project_path(@project)
  end

  private

  def assigned_task_params
    params.require(:assigned_task).permit(:project_id, :task_id)
  end

  def ensure_membership
    project = authorized_scope(Project, type: :relation).find(params[:project_id])

    return if project.memberships.exists?(user_id: current_user)

    flash[:alert] = "Access denied"
    redirect_to root_path
  end
end
