class Users::ApiTokensController < AuthenticatedController
  # The Devise registrations edit view relies on these helpers.
  helper_method :resource, :resource_name

  def create
    authorize! current_user, to: :regenerate_token?, with: UserPolicy

    @api_token = current_user.regenerate_api_token!
    render "devise/registrations/edit", status: :unprocessable_entity
  end

  private

  def resource
    current_user
  end

  def resource_name
    :user
  end
end
