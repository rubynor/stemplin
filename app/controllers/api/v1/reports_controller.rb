module Api
  module V1
    class ReportsController < BaseController
      def index
        authorize!
        scope = authorized_scope(TimeReg, type: :relation)
        scope = scope.between_dates(params[:start_date], params[:end_date]) if params[:start_date] && params[:end_date]
        scope = scope.by_clients(params[:client_ids]) if params[:client_ids]
        scope = scope.by_projects(params[:project_ids]) if params[:project_ids]
        scope = scope.by_users(params[:user_ids]) if params[:user_ids]
        scope = scope.by_tasks(params[:task_ids]) if params[:task_ids]

        @total_minutes = scope.sum(:minutes)
        @total_entries = scope.count

        @by_project = scope
          .joins(assigned_task: { project: :client })
          .group("projects.id", "projects.name", "clients.name")
          .select("projects.id AS project_id, projects.name AS project_name, clients.name AS client_name, SUM(time_regs.minutes) AS total_minutes, COUNT(time_regs.id) AS total_entries")

        @by_user = scope
          .joins(:user)
          .group("users.id", "users.first_name", "users.last_name")
          .select("users.id AS user_id, users.first_name, users.last_name, SUM(time_regs.minutes) AS total_minutes, COUNT(time_regs.id) AS total_entries")
      end
    end
  end
end
