class RegenerateApiTokenTool < ApplicationTool
  description "Regenerate the API token for the current user"

  arguments do
  end

  def call
    raise "Unauthorized" unless current_user

    token = current_user.regenerate_api_token!

    JSON.generate({ api_token: token })
  rescue => e
    format_error(e)
  end
end
