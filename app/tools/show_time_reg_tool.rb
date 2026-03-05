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
end
