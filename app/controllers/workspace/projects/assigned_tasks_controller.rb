module Workspace
  module Projects
    class AssignedTasksController < ApplicationController
      skip_verify_authorized

      # This controller does not persist any data, but is used for the 'Tasks' section in the Project form.

      def add_modal
        @is_new_task = (params[:is_new_task] == "true") || false
        @unassigned_tasks = authorized_scope(Task, type: :relation).where.not(id: taken_task_ids)
        @is_new_task = true if @unassigned_tasks.blank?

        @assigned_task = authorized_scope(AssignedTask, type: :relation).new(project: @project)
        @assigned_task.build_task
      end

      def add
        @task = authorized_scope(Task, type: :relation).find_or_initialize_by(name: assigned_task_params[:task_attributes][:name])
        @assigned_task = authorized_scope(AssignedTask, type: :relation).new(project: nil, task: @task, rate_nok: assigned_task_params[:rate_nok])
        @assigned_task.build_project

        if @assigned_task.valid?
          render turbo_stream: [
            turbo_stream.action(:remove_modal, :modal),
            turbo_stream.append("project_form_assigned_tasks", partial: "workspace/projects/form_assigned_task", locals: { assigned_task: @assigned_task })
          ]
        else
          @unassigned_tasks = authorized_scope(Task, type: :relation).where(id: unassigned_task_ids)
          @is_new_task = ActiveModel::Type::Boolean.new.cast(assigned_task_params[:task_attributes][:is_new_task])
          render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/projects/assigned_tasks/form", locals: { assigned_task: @assigned_task, unassigned_tasks: @unassigned_tasks, is_new_task: @is_new_task }), status: :unprocessable_entity
        end
      end

      def remove
        @domid = params[:domid]
        @assigned_task = authorized_scope(AssignedTask, type: :relation).find_by(id: params[:assigned_task_id])

        if @assigned_task
          render turbo_stream: turbo_stream.replace(@domid, partial: "workspace/projects/form_assigned_task", locals: { assigned_task: @assigned_task, destroy: true })
        else
          render turbo_stream: turbo_stream.remove(@domid)
        end
      end

      private

      def assigned_task_params
        params.require(:assigned_task).permit(:rate_nok, task_attributes: [ :name, :is_new_task, :unassigned_task_ids ])
      end

      def taken_task_ids
        JSON.parse(params[:taken_task_ids] || "[]")
      end

      def unassigned_task_ids
        JSON.parse(assigned_task_params[:task_attributes][:unassigned_task_ids] || "[]")
      end
    end
  end
end
