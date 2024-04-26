module Workspace
  # TODO: This controller has similar actions to the clients controller, consider refactoring
  # extract duplicated code to a concern
  class TasksController < WorkspaceController
    before_action :set_task, only: %i[edit_modal update destroy]

    def index
      @tasks = authorized_scope(Task, type: :relation).all
    end

    def new_modal
      @task = authorized_scope(Task, type: :relation).new
    end

    def create
      @task = authorized_scope(Task, type: :relation).new(task_params)

      if @task.save
        render turbo_stream: [
          turbo_flash(type: :success, data: "Task was successfully created."),
          turbo_stream.append(:organization_tasks, partial: "workspace/tasks/task", locals: { task: @task }),
          turbo_stream.action(:remove_modal, :modal)
        ]
      else
        render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/tasks/form", locals: { task: @task })
      end
    end

    def edit_modal
    end

    def update
      if @task.update(task_params)
        render turbo_stream: [
          turbo_flash(type: :success, data: "Task was successfully updated."),
          turbo_stream.replace(dom_id(@task), partial: "workspace/tasks/task", locals: { task: @task }),
          turbo_stream.action(:remove_modal, :modal)
        ]
      else
        render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/tasks/task", locals: { task: @task })
      end
    end

    def destroy
      if @task.assigned_tasks.any?
        render turbo_stream: turbo_flash(type: :error, data: "Unable to proceed, Task is assigned to a project.")
      else
        @task.destroy!
        render turbo_stream: [
          turbo_flash(type: :success, data: "Task was successfully deleted."),
          turbo_stream.remove(dom_id(@task)),
          turbo_stream.action(:remove_modal, :modal)
        ]
      end
    end

    private

    def task_params
      params.require(:task).permit(:name)
    end

    def set_task
      @task = Task.find(params[:id])
      authorize! @task
    end
  end
end
