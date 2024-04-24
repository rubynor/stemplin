module Workspace
  module Projects
    class AssignedTasksController < ProjectsController
      before_action :set_project
      before_action :set_assigned_task, only: %i[delete_confirmation destroy]

      def new_modal
        @unassigned_tasks = authorized_scope(Task, type: :relation).unassigned_tasks(@project.id)
        @assigned_task = authorized_scope(AssignedTask, type: :relation).new
      end

      def create
        @assigned_task = authorized_scope(AssignedTask, type: :relation).new(project: @project, task_id: assigned_task_params[:task_id])

        if @assigned_task.save
          render turbo_stream: [
            turbo_flash(type: :success, data: "Task added to project."),
            turbo_stream.action(:remove_modal, :modal),
            turbo_stream.append("#{dom_id(@project)}_assigned_tasks", partial: "workspace/projects/assigned_task", locals: { assigned_task: @assigned_task })
          ]
        else
          @unassigned_tasks = authorized_scope(Task, type: :relation).unassigned_tasks(@project.id)
          render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/projects/assigned_tasks/form", locals: { project: @project, assigned_task: @assigned_task, unassigned_tasks: @unassigned_tasks })
        end
      end

      def delete_confirmation
      end

      def destroy
        if @assigned_task.destroy
          render turbo_stream: [
            turbo_flash(type: :success, data: "Task removed from project."),
            turbo_stream.remove(dom_id(@assigned_task)),
            turbo_stream.action(:remove_modal, :modal)
          ]
        else
          render turbo_stream: turbo_flash(type: :error, data: "Unable to proceed, #{@assigned_task.errors.full_messages.join(", ")}.")
        end
      end

      private

      def set_project
        @project = authorized_scope(Project, type: :relation).find(params[:project_id])
      end

      def assigned_task_params
        params.require(:assigned_task).permit(:task_id)
      end

      def set_assigned_task
        @assigned_task = authorized_scope(AssignedTask, type: :relation).find(params[:id])
      end
    end
  end
end
