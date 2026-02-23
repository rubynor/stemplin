module Api
  module V1
    class TasksController < BaseController
      def index
        authorize! Task, to: :index?
        tasks = authorized_scope(Task, type: :relation).order(:name)
        render json: tasks.map { |task| task_json(task) }
      end

      def show
        task = authorized_scope(Task, type: :relation).find(params[:id])
        authorize! task
        render json: task_json(task)
      end

      private

      def task_json(task)
        {
          id: task.id,
          name: task.name,
          organization_id: task.organization_id,
          created_at: task.created_at,
          updated_at: task.updated_at
        }
      end
    end
  end
end
