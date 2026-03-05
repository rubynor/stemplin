class ShowClientTool < ApplicationTool
  description "Show details of a specific client"

  arguments do
    required(:id).filled(:integer).description("Client ID")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(id:, organization_id: nil)
    resolve_organization(organization_id)

    client = authorized_scope(Client, type: :relation, with: ClientPolicy).find(id)
    authorize! client, with: ClientPolicy, to: :show?

    JSON.generate({
      id: client.id,
      name: client.name,
      organization_id: client.organization_id,
      created_at: client.created_at,
      updated_at: client.updated_at
    })
  rescue => e
    format_error(e)
  end
end
