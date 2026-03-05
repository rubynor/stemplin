class DeleteTimeRegTool < ApplicationTool
  description "Delete a time registration (soft delete)"

  arguments do
    required(:id).filled(:integer).description("Time registration ID")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(id:, organization_id: nil)
    resolve_organization(organization_id)

    time_reg = authorized_scope(TimeReg, type: :relation, as: :own).find(id)
    authorize! time_reg, with: TimeRegPolicy, to: :destroy?
    time_reg.discard!

    JSON.generate({ status: "deleted", id: time_reg.id })
  rescue => e
    format_error(e)
  end
end
