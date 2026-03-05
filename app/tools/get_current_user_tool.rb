class GetCurrentUserTool < ApplicationTool
  description "Get the currently authenticated user's information"

  arguments do
  end

  def call
    raise "Unauthorized" unless current_user

    user = current_user
    org = user.current_organization

    JSON.generate({
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      locale: user.locale,
      name: user.name,
      created_at: user.created_at,
      updated_at: user.updated_at,
      has_api_token: user.api_token_digest.present?,
      current_organization: org ? { id: org.id, name: org.name } : nil
    })
  rescue => e
    format_error(e)
  end
end
