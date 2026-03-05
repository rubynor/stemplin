class GetReportsTool < ApplicationTool
  description "Get aggregated time registration reports"

  arguments do
    required(:start_date).filled(:string).description("Report start date (YYYY-MM-DD)")
    required(:end_date).filled(:string).description("Report end date (YYYY-MM-DD)")
    optional(:client_ids).filled(:string).description("Comma-separated client IDs to filter by")
    optional(:project_ids).filled(:string).description("Comma-separated project IDs to filter by")
    optional(:user_ids).filled(:string).description("Comma-separated user IDs to filter by")
    optional(:task_ids).filled(:string).description("Comma-separated task IDs to filter by")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(start_date:, end_date:, client_ids: nil, project_ids: nil, user_ids: nil, task_ids: nil, organization_id: nil)
    resolve_organization(organization_id)
    authorize! with: ReportPolicy, to: :index?

    scope = authorized_scope(TimeReg, type: :relation, with: TimeRegPolicy)
    scope = scope.between_dates(start_date, end_date)
    scope = scope.by_clients(client_ids.split(",").map(&:strip)) if client_ids
    scope = scope.by_projects(project_ids.split(",").map(&:strip)) if project_ids
    scope = scope.by_users(user_ids.split(",").map(&:strip)) if user_ids
    scope = scope.by_tasks(task_ids.split(",").map(&:strip)) if task_ids

    total_minutes = scope.sum(:minutes)
    total_entries = scope.count

    by_project = scope
      .joins(assigned_task: { project: :client })
      .group("projects.id", "projects.name", "clients.name")
      .select("projects.id AS project_id, projects.name AS project_name, clients.name AS client_name, SUM(time_regs.minutes) AS total_minutes, COUNT(time_regs.id) AS total_entries")

    by_user = scope
      .joins(:user)
      .group("users.id", "users.first_name", "users.last_name")
      .select("users.id AS user_id, users.first_name, users.last_name, SUM(time_regs.minutes) AS total_minutes, COUNT(time_regs.id) AS total_entries")

    JSON.generate({
      total_minutes: total_minutes,
      total_entries: total_entries,
      by_project: by_project.map { |row|
        {
          project_id: row.project_id,
          project_name: row.project_name,
          client_name: row.client_name,
          total_minutes: row.total_minutes.to_i,
          total_entries: row.total_entries.to_i
        }
      },
      by_user: by_user.map { |row|
        {
          user_id: row.user_id,
          user_name: "#{row.first_name} #{row.last_name}".strip,
          total_minutes: row.total_minutes.to_i,
          total_entries: row.total_entries.to_i
        }
      }
    })
  rescue => e
    format_error(e)
  end
end
