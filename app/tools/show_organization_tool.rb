class ShowOrganizationTool < ApplicationTool
  description "Show details of a specific organization the user belongs to"

  arguments do
    required(:id).filled(:integer).description("Organization ID")
    optional(:organization_id).filled(:integer).description("Organization ID (not used for this tool, included for consistency)")
  end

  def call(id:, organization_id: nil)
    raise "Unauthorized" unless current_user

    org = current_user.organizations.find(id)
    JSON.generate({
      id: org.id,
      name: org.name,
      currency: org.currency,
      created_at: org.created_at,
      updated_at: org.updated_at
    })
  rescue => e
    format_error(e)
  end
end
