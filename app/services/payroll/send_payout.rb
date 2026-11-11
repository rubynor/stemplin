module Payroll
  # Pays one member's locked month through Tripletex: one salary run with one payslip and one hourly-wage line.
  #
  # The order is what prevents paying twice. The payout row is inserted (and committed) as pending before
  # Tripletex is called, so a second request hits the unique index. After that, the row is only removed when
  # Tripletex certainly holds no run for it; whenever a run may exist, the row stays as unclear.
  # The caller authorizes the admin, and must not call this inside a transaction (the pending row must be committed).
  class SendPayout
    def initialize(organization:, user:, period:, sent_by:, expected_rate:)
      @organization = organization
      @user = user
      @period = period.to_date.beginning_of_month
      @sent_by = sent_by
      @expected_rate = expected_rate
    end

    def call
      integration = @organization.tripletex_integration
      refuse(:not_connected) unless integration
      refuse(:no_salary_type) unless integration.hourly_salary_type_id
      employee_id = AccessInfo.find_by(organization_id: @organization.id, user_id: @user.id)&.tripletex_employee_id
      refuse(:not_linked) unless employee_id
      lock = TimeLock.where(organization_id: @organization.id, user_id: @user.id).for_period(@period).first
      refuse(:not_locked) unless lock
      minutes = TimeLock.minutes_in(user: @user, organization: @organization, period: @period)
      refuse(:no_hours) unless minutes.positive?

      @api = integration.api
      rule = pay_rule(employee_id)
      refuse(:wage_changed) unless @expected_rate.is_a?(BigDecimal) && rule.rate == @expected_rate

      payout = insert_pending(lock:, employee_id:, minutes:, rule:)
      send_to_tripletex(payout, salary_type_id: integration.hourly_salary_type_id)
    end

    private

    def refuse(key, **args)
      raise Error, I18n.t("tripletex.payroll.errors.#{key}", **args)
    end

    # Always asked fresh: the wage sent must be the wage Tripletex holds now.
    def pay_rule(employee_id)
      pay = @api.pay_details([ employee_id ], on: @period.end_of_month)[employee_id]
      PayRules.for(pay) || refuse(:unsupported)
    rescue Tripletex::Error => e
      refuse(:pay_unavailable, message: e.message)
    end

    # Committed before any Tripletex call. Locking the TimeLock row means an unlock cannot slip in between
    # the check above and this insert: TimeLocksController takes the same lock before checking sent?.
    def insert_pending(lock:, employee_id:, minutes:, rule:)
      PayrollPayout.transaction do
        refuse(:not_locked) unless TimeLock.lock.find_by(id: lock.id)

        PayrollPayout.create!(
          organization: @organization, user: @user, period: @period, status: :pending,
          minutes: minutes, hours: rule.count(minutes), hourly_wage: rule.rate, amount: rule.amount(minutes),
          tripletex_employee_id: employee_id, sent_by: @sent_by
        )
      end
    rescue ActiveRecord::RecordNotUnique
      refuse(:already_sent)
    end

    def send_to_tripletex(payout, salary_type_id:)
      @write_attempted = false
      run = create_run(payout)
      payout.update!(tripletex_transaction_id: run["transaction_id"], tripletex_payslip_id: run["payslip_id"])
      add_line(payout, run, salary_type_id)
      payout.update!(status: :sent, sent_at: Time.current)
      payout
    rescue Error
      raise
    rescue StandardError => e
      # A bug or a database error. Without a Tripletex write there is nothing to check; otherwise a run may exist.
      # If even this cannot be stored, the row stays pending, which an admin can resolve once it is stale.
      begin
        @write_attempted ? unclear!(payout, e.message) : payout.destroy!
      rescue StandardError => store_error
        Rails.logger.error("Payroll::SendPayout could not record failure of payout #{payout.id}: #{store_error.message}")
      end
      refuse(@write_attempted ? :unclear : :failed, message: e.message)
    end

    def create_run(payout)
      @write_attempted = true
      @api.create_salary_run(employee_id: payout.tripletex_employee_id, year: Date.current.year, month: Date.current.month,
                             date: Date.current, description: run_description)
    rescue Tripletex::UncertainError => e
      unclear!(payout, e.message)
      refuse(:unclear, message: e.message)
    rescue Tripletex::Error => e
      payout.destroy!
      refuse(:rejected, message: e.message)
    end

    # Whatever went wrong, the half-made run is deleted so a retry starts clean. Only a confirmed delete
    # releases the month; if the delete fails too, a run may still exist.
    def add_line(payout, run, salary_type_id)
      @api.add_salary_line(transaction_id: run["transaction_id"], payslip_id: run["payslip_id"],
                           salary_type_id: salary_type_id, rate: payout.hourly_wage, count: payout.hours)
    rescue Tripletex::Error => e
      begin
        @api.delete_salary_run(run["transaction_id"])
      rescue Tripletex::Error => delete_error
        unclear!(payout, "#{e.message} / #{delete_error.message}")
        refuse(:unclear, message: e.message)
      end
      payout.destroy!
      refuse(:rejected, message: e.message)
    end

    # The row keeps blocking a retry until an admin resolves it.
    def unclear!(payout, message)
      payout.update!(status: :unclear, error_message: message)
    end

    def run_description
      month = I18n.l(@period, format: "%B %Y", locale: :nb)
      I18n.t("tripletex.payroll.run_description", month: month, locale: :nb)
    end
  end
end
