module Profiles
  # The API tokens card on the profile page.
  class ApiTokensController < AuthenticatedController
    before_action :set_api_token, only: %i[update destroy]

    def create
      authorize! ApiToken
      api_token = ApiToken.new(api_token_params.merge(user: current_user))

      if api_token.save
        # The secret leaves the server in this response only: it is never put
        # in the flash, the session or a redirect, and cannot be read back.
        render_section(revealed: api_token)
      else
        render_section(new_api_token: api_token, status: :unprocessable_entity)
      end
    end

    def update
      authorize! @api_token

      if @api_token.update(api_token_params)
        redirect_to profile_path, notice: t("api_token.renamed"), status: :see_other
      else
        render_section(editing: @api_token, status: :unprocessable_entity)
      end
    end

    def destroy
      authorize! @api_token
      @api_token.destroy!

      redirect_to profile_path, notice: t("api_token.deleted"), status: :see_other
    end

    private

    def set_api_token
      @api_token = authorized_scope(ApiToken, type: :relation).find(params[:id])
    end

    def api_token_params
      params.require(:api_token).permit(:name)
    end

    def render_section(status: :ok, **locals)
      render turbo_stream: turbo_stream.replace(
        :api_token_section,
        partial: "profiles/api_tokens/section",
        locals: { user: current_user, **locals }
      ), status: status
    end
  end
end
