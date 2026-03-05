class ListClientsTool < ApplicationTool
  description "List all clients in the organization"

  arguments do
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(organization_id: nil)
    resolve_organization(organization_id)
    authorize! with: ClientPolicy, to: :index?

    clients = authorized_scope(Client, type: :relation, with: ClientPolicy).order(:name)
    JSON.generate(clients.map { |client|
      {
        id: client.id,
        name: client.name,
        organization_id: client.organization_id,
        created_at: client.created_at,
        updated_at: client.updated_at
      }
    })
  rescue => e
    format_error(e)
  end
end
