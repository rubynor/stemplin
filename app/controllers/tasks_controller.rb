class TasksController < ApplicationController
  before_action :authenticate_user!
  def index
    @tasks = Task.all
  end

  def show
    @task = Task.find(params[:id])
  end

  def new
    @task = Task.new
  end

  def create
    @task = Task.new(task_params)

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
  end

  def update
    @task = Task.find(params[:id])

    if @task.update(task_params)
      flash[:notice] = t('notice.task_has_been_updated')
      redirect_to tasks_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task = Task.find(params[:id])

    if @task.assigned_tasks.empty?
      if @task.destroy
        flash[:notice] = t('notice.task_was_successfully_deleted')
        redirect_to tasks_path
      else
        flash[:alert] = t('alert.could_not_delete_task')
        redirect_to edit_task_path(@task)
      end
    else
      flash[:alert] = t('alert.task_is_being_used_in_one_or_more_projects')
      redirect_to edit_task_path(@task)
    end
  end

  private

  def render_turbo_frames
    set_turbo_frame_data

    render partial: "assigned_tasks/new", locals: {
      project: @project,
      assigned_task: @assigned_task,
      task: Task.new,
      tasks: @tasks
    }
  end

  def set_turbo_frame_data
    @project = Project.find(params[:task][:project_id])
    @assigned_task = @project.assigned_tasks.new
    @tasks = Task.all.where.not(id: @project.assigned_tasks.select(:task_id)).select(:id, :name)
  end

  def task_params
    params.require(:task).permit(:name)
  end
end
