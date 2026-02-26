module Api
  module V1
    class ProjectsController < BaseController
      before_action :set_project, only: %i[show update destroy]

      def index
        authorize!
        @projects = authorized_scope(Project, type: :relation).includes(:client).order(:name)
      end

      def show
        authorize! @project
        load_assigned_tasks
      end

      def create
        @project = Project.new(project_params)
        authorize! @project
        @project.save!
        load_assigned_tasks
        render :show, status: :created
      end

      def update
        authorize! @project
        @project.update!(project_params)
        load_assigned_tasks
        render :show
      end

      def destroy
        authorize! @project
        @project.discard!
        head :no_content
      end

      private

      def set_project
        @project = authorized_scope(Project, type: :relation).find(params[:id])
      end

      def load_assigned_tasks
        @assigned_tasks = @project.active_assigned_tasks.includes(:task)
      end

      def project_params
        params.require(:project).permit(:name, :description, :billable, :rate_currency, :client_id,
          assigned_tasks_attributes: [ :id, :rate, :_destroy, :task_id, task_attributes: [ :name, :organization_id ] ])
      end
    end
  end
end
