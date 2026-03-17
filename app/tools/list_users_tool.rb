class ListUsersTool < ApplicationTool
  description "List all users in the organization"

  arguments do
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(organization_id: nil)
    resolve_organization(organization_id)
    authorize! with: UserPolicy, to: :index?

    users = authorized_scope(User, type: :relation, with: UserPolicy).onboarded.ordered_by_name

    JSON.generate(users.map { |user| format_user(user) })
  rescue => e
    format_error(e)
  end

  private

  def format_user(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      locale: user.locale,
      name: user.name,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
