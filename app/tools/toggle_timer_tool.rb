class ToggleTimerTool < ApplicationTool
  description "Toggle the timer on a time registration (start/stop)"

  arguments do
    required(:time_reg_id).filled(:integer).description("Time registration ID")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(time_reg_id:, organization_id: nil)
    resolve_organization(organization_id)

    time_reg = authorized_scope(TimeReg, type: :relation, as: :own).find(time_reg_id)
    authorize! time_reg, with: TimeRegPolicy, to: :toggle_active?
    time_reg.toggle_active

    JSON.generate(format_time_reg(time_reg))
  rescue => e
    format_error(e)
  end
end
