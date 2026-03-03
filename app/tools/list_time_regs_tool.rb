class ListTimeRegsTool < ApplicationTool
  description "List time registrations for the current user"

  arguments do
    optional(:date).filled(:string).description("Filter by specific date (YYYY-MM-DD)")
    optional(:start_date).filled(:string).description("Filter start date (YYYY-MM-DD)")
    optional(:end_date).filled(:string).description("Filter end date (YYYY-MM-DD)")
    optional(:project_id).filled(:integer).description("Filter by project ID")
    optional(:page).filled(:integer).description("Page number (default: 1)")
    optional(:per_page).filled(:integer).description("Items per page (default: 25)")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(date: nil, start_date: nil, end_date: nil, project_id: nil, page: 1, per_page: 25, organization_id: nil)
    resolve_organization(organization_id)
    authorize! with: TimeRegPolicy, to: :index?

    scope = authorized_scope(TimeReg, type: :relation, as: :own)
    scope = scope.between_dates(start_date, end_date) if start_date && end_date
    scope = scope.on_date(Date.parse(date)) if date
    scope = scope.by_projects(project_id) if project_id

    scope = scope.includes(assigned_task: [ :task, { project: :client } ]).order(date_worked: :desc, created_at: :desc)

    total_count = scope.count
    per_page = [ [ per_page.to_i, 1 ].max, 100 ].min
    page = [ page.to_i, 1 ].max
    total_pages = (total_count.to_f / per_page).ceil
    offset = (page - 1) * per_page

    time_regs = scope.offset(offset).limit(per_page)

    JSON.generate({
      time_regs: time_regs.map { |tr| format_time_reg(tr) },
      pagination: {
        current_page: page,
        total_pages: total_pages,
        total_count: total_count
      }
    })
  rescue => e
    format_error(e)
  end

  private

  def format_time_reg(tr)
    {
      id: tr.id,
      notes: tr.notes,
      minutes: tr.minutes,
      date_worked: tr.date_worked,
      assigned_task_id: tr.assigned_task_id,
      user_id: tr.user_id,
      start_time: tr.start_time,
      created_at: tr.created_at,
      updated_at: tr.updated_at,
      current_minutes: tr.current_minutes,
      active: tr.active?,
      task_name: tr.task&.name,
      project_id: tr.project&.id,
      project_name: tr.project&.name,
      client_name: tr.client&.name
    }
  end
end
