class CreateClientTool < ApplicationTool
  description "Create a new client in the organization"

  arguments do
    required(:name).filled(:string).description("Client name (2-60 characters)")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(name:, organization_id: nil)
    org = resolve_organization(organization_id)

    client = Client.new(name: name)
    client.organization = org
    authorize! client, with: ClientPolicy, to: :create?
    client.save!

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
