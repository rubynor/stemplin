module Workspace
  class PayrollPayoutsController < WorkspaceController
    def create
      organization = current_user.current_organization
      # The top-level UserPolicy scope (not Workspace::UserPolicy's) also covers archived members of the organization.
      user = authorized_scope(User, type: :relation, with: ::UserPolicy).find(params[:user_id])
      authorize! PayrollPayout.new(organization: organization, user: user)

      return redirect_to workspace_payroll_path, flash: { error: t("tripletex.payroll.errors.month_missing") } unless period

      expected_rate = BigDecimal(params[:expected_rate].to_s, exception: false)
      expected_minutes = Integer(params[:expected_minutes].to_s, 10, exception: false)
      if expected_rate.nil?
        flash[:error] = t("tripletex.payroll.errors.rate_missing")
      elsif expected_minutes.nil?
        flash[:error] = t("tripletex.payroll.errors.hours_missing")
      else
        send_payout(organization, user, expected_rate, expected_minutes)
      end
      redirect_to workspace_payroll_path(month: period.strftime("%Y-%m"))
    end

    def mark_sent
      resolve { |payout| payout.mark_sent!(by: current_user) }
    end

    def release
      resolve { |payout| payout.release! }
    end

    private

    def send_payout(organization, user, expected_rate, expected_minutes)
      payout = Payroll::SendPayout.new(organization: organization, user: user, period: period, sent_by: current_user,
                                       expected_rate: expected_rate, expected_minutes: expected_minutes).call
      flash[:success] = t("tripletex.payroll.payout_sent", name: user.name.presence || user.email, month: month_name(payout.period))
    rescue Payroll::Error => e
      flash[:error] = e.message
    end

    def resolve
      payout = authorized_scope(PayrollPayout, type: :relation).find(params[:id])
      authorize! payout
      begin
        yield payout
        flash[:success] = t("tripletex.payroll.#{action_name}_notice", month: month_name(payout.period))
      rescue Payroll::Error => e
        flash[:error] = e.message
      end
      redirect_to workspace_payroll_path(month: payout.period.strftime("%Y-%m"))
    end

    # Nil when the month is missing or unparseable: a payout is never sent for a guessed month.
    def period
      return @period if defined?(@period)

      @period = begin
        Date.strptime(params[:month].to_s, "%Y-%m")
      rescue Date::Error
        nil
      end
    end

    def month_name(date)
      I18n.l(date, format: "%B %Y")
    end

    def implicit_authorization_target
      PayrollPayout
    end
  end
end
