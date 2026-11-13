module Workspace
  class PayrollController < WorkspaceController
    include SetCurrency

    def show
      authorize!
      @organization = current_user.current_organization
      @integration = @organization.tripletex_integration
      return redirect_to workspace_integrations_path unless @integration

      @period = parse_period
      @overview = Payroll::Overview.new(organization: @organization, period: @period)
      @month_ended = @period.end_of_month < Date.current
    end

    private

    def default_period
      Date.current.last_month.beginning_of_month
    end

    def parse_period
      period = Date.strptime(params[:month].to_s, "%Y-%m")
      period.year.between?(2000, 2100) ? period : default_period
    rescue Date::Error
      default_period
    end

    def implicit_authorization_target
      :payroll
    end
  end
end
