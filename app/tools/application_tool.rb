class ApplicationTool < ActionTool::Base
  include ActionPolicy::Behaviour

  authorize :user, through: :current_user

  private

  def current_user
    @current_user ||= begin
      token = headers&.dig("Authorization")&.delete_prefix("Bearer ")
      User.find_by_api_token(token)
    end
  end

  def resolve_organization(organization_id = nil)
    raise "Unauthorized" unless current_user

    if organization_id.present?
      org = Organization.find(organization_id)
      access = current_user.access_info(org)
      raise ActiveRecord::RecordNotFound, "Organization not found or no access" unless access
    else
      access = current_user.access_info
      raise "No default organization. Pass organization_id argument." unless access
    end

    current_user.define_singleton_method(:access_info) do |o = nil|
      return current_user.access_infos.find_by(organization: o) if o
      access
    end

    access.organization
  end

  def format_error(exception)
    case exception
    when ActiveRecord::RecordNotFound
      JSON.generate({ error: "Not found" })
    when ActiveRecord::RecordInvalid
      JSON.generate({ error: exception.record.errors.full_messages.join(", ") })
    when ActionPolicy::Unauthorized
      JSON.generate({ error: "Forbidden" })
    else
      JSON.generate({ error: exception.message })
    end
  end
end
