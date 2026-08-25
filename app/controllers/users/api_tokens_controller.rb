class Users::ApiTokensController < AuthenticatedController
  def create
    authorize! current_user, to: :regenerate_token?, with: UserPolicy

    # The plaintext token exists only in this response (a turbo_stream swap of
    # the section, 200 OK) — it is never placed in the flash/session/cookies.
    @api_token = current_user.regenerate_api_token!
    render turbo_stream: turbo_stream.replace(
      :api_token_section,
      partial: "users/api_tokens/section",
      locals: { user: current_user, api_token: @api_token }
    )
  end
end
