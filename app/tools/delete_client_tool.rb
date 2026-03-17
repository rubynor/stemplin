class DeleteClientTool < ApplicationTool
  description "Delete a client (soft delete)"

  arguments do
    required(:id).filled(:integer).description("Client ID")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(id:, organization_id: nil)
    resolve_organization(organization_id)

    client = authorized_scope(Client, type: :relation, with: ClientPolicy).find(id)
    authorize! client, with: ClientPolicy, to: :destroy?
    client.discard!

    JSON.generate({ status: "deleted", id: client.id })
  rescue => e
    format_error(e)
  end
end
