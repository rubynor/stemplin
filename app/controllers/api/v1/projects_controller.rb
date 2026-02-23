module Api
  module V1
    class ProjectsController < BaseController
      before_action :set_project, only: %i[show update destroy]

      def index
        authorize! Project, to: :index?
        projects = authorized_scope(Project, type: :relation).includes(:client).order(:name)
        render json: projects.map { |project| project_json(project) }
      end

      def show
        authorize! @project
        render json: project_json(@project, detailed: true)
      end

      def create
        project = Project.new(project_params)
        authorize! project
        project.save!
        render json: project_json(project), status: :created
      end

      def update
        authorize! @project
        @project.update!(project_params)
        render json: project_json(@project)
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

      def project_params
        params.require(:project).permit(:name, :description, :billable, :rate_currency, :client_id,
          assigned_tasks_attributes: [ :id, :rate, :_destroy, :task_id, task_attributes: [ :name, :organization_id ] ])
      end

      def project_json(project, detailed: false)
        json = {
          id: project.id,
          name: project.name,
          description: project.description,
          billable: project.billable,
          rate: project.rate,
          rate_currency: project.rate_currency,
          client_id: project.client_id,
          client_name: project.client&.name,
          created_at: project.created_at,
          updated_at: project.updated_at
        }

        if detailed
          json[:assigned_tasks] = project.active_assigned_tasks.includes(:task).map do |at|
            {
              id: at.id,
              task_id: at.task_id,
              task_name: at.task.name,
              rate: at.rate,
              rate_currency: at.rate_currency
            }
          end
        end

        json
      end
    end
  end
end
