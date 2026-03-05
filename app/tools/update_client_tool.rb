class UpdateClientTool < ApplicationTool
  description "Update an existing client"

  arguments do
    required(:id).filled(:integer).description("Client ID")
    required(:name).filled(:string).description("New client name (2-60 characters)")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(id:, name:, organization_id: nil)
    resolve_organization(organization_id)

    client = authorized_scope(Client, type: :relation, with: ClientPolicy).find(id)
    authorize! client, with: ClientPolicy, to: :update?
    client.update!(name: name)

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
