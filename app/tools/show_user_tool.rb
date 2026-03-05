class ShowUserTool < ApplicationTool
  description "Show details of a specific user"

  arguments do
    required(:id).filled(:integer).description("User ID")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(id:, organization_id: nil)
    resolve_organization(organization_id)

    user = authorized_scope(User, type: :relation, with: UserPolicy).find(id)
    authorize! user, with: UserPolicy, to: :show?

    JSON.generate({
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      locale: user.locale,
      name: user.name,
      created_at: user.created_at,
      updated_at: user.updated_at
    })
  rescue => e
    format_error(e)
  end
end
