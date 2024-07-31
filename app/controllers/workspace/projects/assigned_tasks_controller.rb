module Workspace
  module Projects
    class AssignedTasksController < ApplicationController
      skip_verify_authorized

      # This controller does not persist any data, but is used for the 'Tasks' section in the Project form.

      def add_modal
        @unassigned_tasks = authorized_scope(Task, type: :relation).where.not(id: taken_task_ids).order(:name)
        @assigned_task = authorized_scope(AssignedTask, type: :relation).new
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
          render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/projects/assigned_tasks/form", locals: { assigned_task: @assigned_task, unassigned_tasks: @unassigned_tasks, edit: false }), status: :unprocessable_entity
        end
      end

      def edit_modal
        @unassigned_tasks = authorized_scope(Task, type: :relation).where.not(id: taken_task_ids).order(:name)
        @domid = params[:domid]
        @assigned_task = authorized_scope(AssignedTask, type: :relation).new(edit_modal_assigned_task_params)
      end

      def edit
        @task = authorized_scope(Task, type: :relation).find_or_initialize_by(name: assigned_task_params[:task_attributes][:name])
        @assigned_task = authorized_scope(AssignedTask, type: :relation).new(project: nil, task: @task, id: assigned_task_params[:id], rate_nok: assigned_task_params[:rate_nok])
        @assigned_task.build_project
        @domid = assigned_task_params[:domid]

        if @assigned_task.valid?
          render turbo_stream: [
            turbo_stream.action(:remove_modal, :modal),
            turbo_stream.replace(@domid, partial: "workspace/projects/form_assigned_task", locals: { assigned_task: @assigned_task })
          ]
        else
          @unassigned_tasks = authorized_scope(Task, type: :relation).where(id: unassigned_task_ids)
          render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/projects/assigned_tasks/form", locals: { assigned_task: @assigned_task, unassigned_tasks: @unassigned_tasks, edit: true, domid: @domid }), status: :unprocessable_entity
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
        params.require(:assigned_task).permit(:id, :domid, :rate_nok, task_attributes: [ :name, :unassigned_task_ids ])
      end

      def edit_modal_assigned_task_params
        params.require(:assigned_task).permit(:id, :rate_nok, task_attributes: [ :name ])
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
