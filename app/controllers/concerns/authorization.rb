module Authorization
  extend ActiveSupport::Concern

  included do
    verify_authorized unless: :skip_authorization?

    rescue_from ActionPolicy::Unauthorized do |ex|
      redirect_to current_user&.access_info&.organization_spectator? ? reports_path : root_path
    end
  end

  private

  def skip_authorization?
    devise_controller? || !user_signed_in?
  end
end
