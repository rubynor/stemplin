class ListProjectsTool < ApplicationTool
  description "List all projects in the organization"

  arguments do
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(organization_id: nil)
    resolve_organization(organization_id)
    authorize! current_user.access_info.organization, with: ProjectPolicy, to: :index?

    projects = authorized_scope(Project, type: :relation, with: ProjectPolicy).includes(:client).order(:name)
    JSON.generate(projects.map { |project|
      {
        id: project.id,
        name: project.name,
        description: project.description,
        billable: project.billable,
        rate: project.rate,
        rate_currency: project.rate_currency,
        client_id: project.client_id,
        client_name: project.client.name,
        created_at: project.created_at,
        updated_at: project.updated_at
      }
    })
  rescue => e
    format_error(e)
  end
end
