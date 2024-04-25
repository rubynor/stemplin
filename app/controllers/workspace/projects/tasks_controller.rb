module Workspace
  module Projects
    class TasksController < ProjectsController
      before_action :set_project

      def new_modal
        @task = authorized_scope(Task, type: :relation).new
      end

      def create
        @task = authorized_scope(Task, type: :relation).new(task_params.except(:new_assigned_task_rate_nok))

        ActiveRecord::Base.transaction do
          @task.save!
          @assigned_task = AssignedTask.create!(project: @project, task: @task, rate_nok: task_params[:new_assigned_task_rate_nok])
          render turbo_stream: [
            turbo_flash(type: :success, data: "Task was added to the project."),
            turbo_stream.append("#{dom_id(@project)}_assigned_tasks", partial: "workspace/projects/assigned_task", locals: { assigned_task: @assigned_task }),
            turbo_stream.action(:remove_modal, :modal)
          ]
        rescue => e
          render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/projects/tasks/form", locals: { project: @project, task: @task })
        end
      end

      private

      def set_project
        @project = authorized_scope(Project, type: :relation).find(params[:project_id])
      end

      def task_params
        params.require(:task).permit(:name, :new_assigned_task_rate_nok)
      end
    end
  end
end
