module Plan
  class BaseController < AuthenticatedController
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_invalid
    rescue_from ActionPolicy::Unauthorized, with: :render_forbidden

    private

    def current_organization
      current_user.current_organization
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end

    def render_not_found
      render json: { errors: [ I18n.t("plan.errors.not_found") ] }, status: :not_found
    end

    def render_invalid(exception)
      render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
    end

    def render_forbidden
      respond_to do |format|
        format.html { redirect_to root_path }
        format.any { render json: { errors: [ I18n.t("plan.errors.forbidden") ] }, status: :forbidden }
      end
    end
  end
end
