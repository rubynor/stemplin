module Api
  module V1
    class TasksController < BaseController
      before_action :set_task, only: %i[show]

      def index
        authorize!
        @tasks = authorized_scope(Task, type: :relation).order(:name)
      end

      def show
        authorize! @task
      end

      private

      def set_task
        @task = authorized_scope(Task, type: :relation).find(params[:id])
      end
    end
  end
end
