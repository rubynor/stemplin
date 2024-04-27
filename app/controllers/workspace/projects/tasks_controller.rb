module Workspace
  module Projects
    class TasksController < ProjectsController
      before_action :set_project

      def new_modal
        @task = authorized_scope(Task, type: :relation).new
        @task.assigned_tasks.build
      end

      def create
        @task = authorized_scope(Task, type: :relation).new(task_params)
        if @task.save
          render turbo_stream: [
            turbo_flash(type: :success, data: "Task was added to the project."),
            turbo_stream.append("#{dom_id(@project)}_assigned_tasks", partial: "workspace/projects/assigned_task", locals: { assigned_task: @task.assigned_tasks.first }),
            turbo_stream.action(:remove_modal, :modal)
          ]
        else
          render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/projects/tasks/form", locals: { project: @project, task: @task })
        end
      end

      private

      def set_project
        @project = authorized_scope(Project, type: :relation).find(params[:project_id])
      end

      def task_params
        params.require(:task).permit(:name, assigned_tasks_attributes: [ :rate_nok, :project_id ])
      end
    end
  end
end
