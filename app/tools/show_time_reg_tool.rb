class ShowTimeRegTool < ApplicationTool
  description "Show details of a specific time registration"

  arguments do
    required(:id).filled(:integer).description("Time registration ID")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(id:, organization_id: nil)
    resolve_organization(organization_id)

    time_reg = authorized_scope(TimeReg, type: :relation, as: :own).find(id)
    authorize! time_reg, with: TimeRegPolicy, to: :show?

    JSON.generate(format_time_reg(time_reg))
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
