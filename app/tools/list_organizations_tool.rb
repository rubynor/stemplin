class ListOrganizationsTool < ApplicationTool
  description "List all organizations the authenticated user belongs to"

  arguments do
    optional(:organization_id).filled(:integer).description("Organization ID (not used for this tool, included for consistency)")
  end

  def call(organization_id: nil)
    raise "Unauthorized" unless current_user

    orgs = current_user.organizations
    JSON.generate(orgs.map { |org|
      {
        id: org.id,
        name: org.name,
        currency: org.currency,
        created_at: org.created_at,
        updated_at: org.updated_at
      }
    })
  rescue => e
    format_error(e)
  end
end
