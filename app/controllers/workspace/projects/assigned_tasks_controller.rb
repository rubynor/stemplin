module Workspace
  module Projects
    class AssignedTasksController < ProjectsController
      before_action :set_project

      def new_modal
        @unassigned_tasks = authorized_scope(Task, type: :relation).unassigned_tasks(@project.id)
        @assigned_task = authorized_scope(AssignedTask, type: :relation).new
        @assigned_task.build_task
      end

      def create
        @task = authorized_scope(Task, type: :relation).find_by(id: assigned_task_params[:task_attributes][:id])
        @assigned_task = authorized_scope(AssignedTask, type: :relation).new(project: @project, task: @task, rate_nok: assigned_task_params[:rate_nok])

        if @assigned_task.save
          render turbo_stream: [
            turbo_flash(type: :success, data: I18n.t("notice.task_successfully_added_to_project")),
            turbo_stream.action(:remove_modal, :modal),
            turbo_stream.append("#{dom_id(@project)}_assigned_tasks", partial: "workspace/projects/assigned_task", locals: { assigned_task: @assigned_task })
          ]
        else
          @assigned_task.build_task
          @unassigned_tasks = authorized_scope(Task, type: :relation).unassigned_tasks(@project.id)
          render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/projects/assigned_tasks/form", locals: { project: @project, assigned_task: @assigned_task, unassigned_tasks: @unassigned_tasks })
        end
      end

      def destroy
        @assigned_task = authorized_scope(AssignedTask, type: :relation).find(params[:id])
        if @assigned_task.destroy
          render turbo_stream: [
            turbo_flash(type: :success, data: I18n.t("notice.task_succesfully_removed_from_project")),
            turbo_stream.remove(dom_id(@assigned_task)),
            turbo_stream.action(:remove_modal, :modal)
          ]
        else
          render turbo_stream: turbo_flash(type: :error, data: "#{I18n.t("alert.unable_to_proceed")}, #{@assigned_task.errors.full_messages.join(", ")}.")
        end
      end

      def edit_modal
        @assigned_task = authorized_scope(AssignedTask, type: :relation).find(params[:id])
      end

      def update
        @assigned_task = authorized_scope(AssignedTask, type: :relation).find(params[:id])
        if @assigned_task.update(assigned_task_params)
          updated_active_task = @assigned_task.updated_active_task
          render turbo_stream: [
            turbo_flash(type: :success, data: I18n.t("notice.task_has_been_updated")),
            turbo_stream.action(:remove_modal, :modal),
            turbo_stream.replace(dom_id(@assigned_task), partial: "workspace/projects/assigned_task", locals: { assigned_task: updated_active_task })
          ]
        else
          render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/projects/assigned_tasks/form", locals: { project: @project, assigned_task: @assigned_task })
        end
      end

      private

      def set_project
        @project = authorized_scope(Project, type: :relation).find(params[:project_id])
      end

      def assigned_task_params
        params.require(:assigned_task).permit(:rate_nok, task_attributes: [ :id, :name ])
      end
    end
  end
end
