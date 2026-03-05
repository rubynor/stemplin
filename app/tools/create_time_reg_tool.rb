class CreateTimeRegTool < ApplicationTool
  description "Create a new time registration"

  arguments do
    required(:assigned_task_id).filled(:integer).description("Assigned task ID")
    required(:minutes).filled(:integer).description("Minutes worked (0-1440)")
    required(:date_worked).filled(:string).description("Date worked (YYYY-MM-DD)")
    optional(:notes).filled(:string).description("Notes about the work done (max 255 characters)")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(assigned_task_id:, minutes:, date_worked:, notes: nil, organization_id: nil)
    resolve_organization(organization_id)

    time_reg = current_user.time_regs.new(
      assigned_task_id: assigned_task_id,
      minutes: minutes,
      date_worked: date_worked,
      notes: notes
    )
    authorize! time_reg, with: TimeRegPolicy, to: :create?
    time_reg.save!

    JSON.generate(format_time_reg(time_reg))
  rescue => e
    format_error(e)
  end
end
