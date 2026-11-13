module Workspace
  # Connects a workspace to Tripletex: the admin pastes an employee token, we verify it by
  # opening a session and reading the company it belongs to, then store it encrypted.
  class TripletexIntegrationsController < WorkspaceController
    before_action :set_organization

    def new
      @tripletex_integration = @organization.tripletex_integration || @organization.build_tripletex_integration
      authorize! @tripletex_integration
    end

    def create
      @tripletex_integration = @organization.tripletex_integration || @organization.build_tripletex_integration
      authorize! @tripletex_integration
      @tripletex_integration.employee_token = params.dig(:tripletex_integration, :employee_token).to_s.strip

      if @tripletex_integration.employee_token.blank?
        @tripletex_integration.errors.add(:employee_token, :blank)
        return render :new, status: :unprocessable_entity
      end

      previous_company_id = @tripletex_integration.company_id_was
      company = @tripletex_integration.api.company
      company_id = company&.dig("id")
      switched_company = previous_company_id.present? && previous_company_id != company_id

      # A different company has other employees and salary types, so the old links and choice are meaningless.
      ActiveRecord::Base.transaction do
        @organization.access_infos.update_all(tripletex_employee_id: nil) if switched_company
        @tripletex_integration.hourly_salary_type_id = nil if switched_company
        @tripletex_integration.update!(company_id: company_id, company_name: company&.dig("name"), connected_at: Time.current)
      end
      redirect_to workspace_integrations_path, flash: { success: t("tripletex.integrations.connected", company: @tripletex_integration.company_name) }
    rescue Tripletex::Error => e
      @tripletex_integration.errors.add(:employee_token, e.message)
      render :new, status: :unprocessable_entity
    end

    def update
      @tripletex_integration = @organization.tripletex_integration || @organization.build_tripletex_integration
      authorize! @tripletex_integration
      return redirect_to workspace_integrations_path unless @tripletex_integration.persisted?

      @tripletex_integration.update!(hourly_salary_type_id: params.dig(:tripletex_integration, :hourly_salary_type_id).presence&.to_i)
      redirect_to workspace_integrations_path, flash: { success: t("tripletex.integrations.salary_type_saved") }
    end

    # Months that were never sent would stay locked with nobody able to unlock them, so they are released.
    # Months with a sent payout stay locked. The employee links are cleared too: the stored company id goes with
    # the integration, so a later connection to another company could not tell the old links are foreign.
    # Refused while a payout is pending or unclear: resolving it needs the integration, and its month
    # would otherwise stay locked with nobody able to unlock it.
    def destroy
      @tripletex_integration = @organization.tripletex_integration || @organization.build_tripletex_integration
      authorize! @tripletex_integration
      return redirect_to workspace_integrations_path unless @tripletex_integration.persisted?

      disconnected = ActiveRecord::Base.transaction do
        # Row locks serialize this with a payout being inserted for one of these months.
        locks = @organization.time_locks.lock.to_a
        next false if @organization.payroll_payouts.where.not(status: :sent).exists?

        locks.reject(&:sent?).each(&:destroy!)
        @organization.access_infos.update_all(tripletex_employee_id: nil)
        @tripletex_integration.destroy!
        true
      end

      if disconnected
        redirect_to workspace_integrations_path, flash: { success: t("tripletex.integrations.disconnected") }
      else
        redirect_to workspace_integrations_path, flash: { error: t("tripletex.integrations.unresolved_payouts") }
      end
    end

    private

    def set_organization
      @organization = current_user.current_organization
    end

    def implicit_authorization_target
      TripletexIntegration
    end
  end
end
