module Workspace
  class IntegrationsController < WorkspaceController
    helper_method :salary_types, :salary_types_error, :selected_salary_type_id

    def show
      @organization = current_user.current_organization
      authorize! @organization
      @tripletex_integration = @organization.tripletex_integration
    end

    private

    # Cached briefly like the employee list; empty with an error message when Tripletex cannot be reached.
    def salary_types
      return @salary_types if defined?(@salary_types)

      integration = @tripletex_integration
      @salary_types = Rails.cache.fetch([ "tripletex_salary_types", integration.id, integration.updated_at.to_i ], expires_in: 5.minutes) do
        integration.api.salary_types
      end
    rescue Tripletex::Error => e
      @salary_types_error = e.message
      @salary_types = []
    end

    def salary_types_error
      salary_types
      @salary_types_error
    end

    # The stored choice, else the type named exactly "Timelønn" (not "Sykelønn - timelønn"); nothing is saved until submitted.
    def selected_salary_type_id
      @tripletex_integration.hourly_salary_type_id ||
        salary_types.find { |type| type["name"].to_s.strip.casecmp?("Timelønn") }&.fetch("id")
    end

    def implicit_authorization_target
      Organization
    end
  end
end
