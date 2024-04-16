class TasksController < ApplicationController
  before_action :authenticate_user!

  def index
    @tasks = authorized_scope(Task, type: :relation).all
  end

  def show
    @task = Task.find(params[:id])
    authorize! @task
  end

  def new
    @task = authorized_scope(Task, type: :relation).new
  end

  def create
    @task = authorized_scope(Task, type: :relation).new(task_params)
    authorize! @task

    if @task.save
      return render_turbo_frames if turbo_frame_request?
      redirect_to tasks_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @is_in_update = true

    @task = Task.find(params[:id])
    authorize! @task
  end

  def update
    @task = Task.find(params[:id])
    authorize! @task

    if @task.update(task_params)
      flash[:notice] = "Task has been updated"
      redirect_to tasks_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task = Task.find(params[:id])
    authorize! @task

    if @task.assigned_tasks.empty?
      if @task.destroy
        flash[:notice] = "Task was successfully deleted."
        redirect_to tasks_path
      else
        flash[:alert] = "Could not delete task."
        redirect_to edit_task_path(@task)
      end
    else
      flash[:alert] = "Task is being used in one or more projects."
      redirect_to edit_task_path(@task)
    end
  end

  private

  def render_turbo_frames
    set_turbo_frame_data

    render partial: "assigned_tasks/new", locals: {
      project: @project,
      assigned_task: @assigned_task,
      task: authorized_scope(Task, type: :relation).new,
      tasks: @tasks
    }
  end

  def set_turbo_frame_data
    @project = authorized_scope(Project, type: :relation).find(params[:task][:project_id])
    @assigned_task = @project.assigned_tasks.new
    @tasks = authorized_scope(Task, type: :relation).all.where.not(id: @project.assigned_tasks.select(:task_id)).select(:id, :name)
  end

  def task_params
    params.require(:task).permit(:name)
  end
end
