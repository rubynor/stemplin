module Api
  module V1
    class ReportsController < BaseController
      def index
        authorize! Report, to: :index?
        scope = authorized_scope(TimeReg, type: :relation)

        scope = scope.between_dates(params[:start_date], params[:end_date]) if params[:start_date] && params[:end_date]
        scope = scope.by_clients(params[:client_ids]) if params[:client_ids]
        scope = scope.by_projects(params[:project_ids]) if params[:project_ids]
        scope = scope.by_users(params[:user_ids]) if params[:user_ids]
        scope = scope.by_tasks(params[:task_ids]) if params[:task_ids]

        time_regs = scope.includes(assigned_task: [ :task, { project: :client } ], user: {})

        summary = {
          total_minutes: time_regs.sum(:minutes),
          total_entries: time_regs.count,
          by_project: time_regs.group_by(&:project).map do |project, regs|
            {
              project_id: project&.id,
              project_name: project&.name,
              client_name: project&.client&.name,
              total_minutes: regs.sum(&:minutes),
              total_entries: regs.size
            }
          end,
          by_user: time_regs.group_by(&:user).map do |user, regs|
            {
              user_id: user.id,
              user_name: user.name,
              total_minutes: regs.sum(&:minutes),
              total_entries: regs.size
            }
          end
        }

        render json: summary
      end
    end
  end
end
