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

      refuse(:wage_precision) unless rule.rate == rule.rate.round(2)

      @payout = insert_pending(lock:, employee_id:, minutes:, rule:)
      send_to_tripletex(salary_type_id: integration.hourly_salary_type_id)
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

    def send_to_tripletex(salary_type_id:)
      @write_attempted = false
      run = create_run
      @transaction_id, @payslip_id = run.values_at("transaction_id", "payslip_id")
      transition!(tripletex_transaction_id: @transaction_id, tripletex_payslip_id: @payslip_id)
      add_line(run, salary_type_id)
      transition!(status: :sent, sent_at: Time.current)
      @payout
    rescue Error
      raise
    rescue StandardError => e
      # A bug or a database error. Without a Tripletex write there is nothing to check; otherwise a run may exist.
      # If even this cannot be stored, the row stays pending, which an admin can resolve once it is stale.
      begin
        @write_attempted ? unclear!(e.message) : discard!
      rescue Error
        raise
      rescue StandardError => store_error
        Rails.logger.error("Payroll::SendPayout could not record failure of payout #{@payout.id}: #{store_error.message}")
      end
      refuse(@write_attempted ? :unclear : :failed, message: e.message)
    end

    def create_run
      @write_attempted = true
      @api.create_salary_run(employee_id: @payout.tripletex_employee_id, year: Date.current.year, month: Date.current.month,
                             date: Date.current, description: run_description)
    rescue Tripletex::UncertainError => e
      unclear!(e.message)
      refuse(:unclear, message: e.message)
    rescue Tripletex::Error => e
      discard!
      refuse(:rejected, message: e.message)
    end

    # Whatever went wrong, the half-made run is deleted so a retry starts clean. Only a confirmed delete
    # releases the month; if the delete fails too, a run may still exist.
    def add_line(run, salary_type_id)
      @api.add_salary_line(transaction_id: run["transaction_id"], payslip_id: run["payslip_id"],
                           salary_type_id: salary_type_id, rate: @payout.hourly_wage, count: @payout.hours)
    rescue Tripletex::Error => e
      begin
        @api.delete_salary_run(run["transaction_id"])
      rescue Tripletex::Error => delete_error
        unclear!("#{e.message} / #{delete_error.message}")
        refuse(:unclear, message: e.message)
      end
      discard!
      refuse(:rejected, message: e.message)
    end

    # The row keeps blocking a retry until an admin resolves it.
    def unclear!(message)
      transition!(status: :unclear, error_message: message)
    end

    # Changes the row only while this send still owns it: it exists and is pending. An admin can release or
    # mark sent a pending row that looks stale (PayrollPayout::IN_FLIGHT_FOR); if that happened, a run may
    # exist in Tripletex that no record accounts for, so a blocking record is put back.
    def transition!(**attributes)
      owned = PayrollPayout.transaction do
        row = PayrollPayout.lock.find_by(id: @payout.id)
        next false unless row&.pending?

        row.update!(attributes)
        @payout = row
        true
      end
      restore_blocking_record! unless owned
    end

    # Only when Tripletex certainly holds no run for this payout. A row no longer ours is left alone.
    def discard!
      PayrollPayout.transaction do
        row = PayrollPayout.lock.find_by(id: @payout.id)
        row.destroy! if row&.pending?
      end
    end

    def restore_blocking_record!
      message = I18n.t("tripletex.payroll.errors.released")
      attributes = { status: :unclear, error_message: message,
                     tripletex_transaction_id: @transaction_id, tripletex_payslip_id: @payslip_id }.compact
      PayrollPayout.transaction do
        if (row = PayrollPayout.lock.find_by(id: @payout.id))
          row.update!(attributes)
        else
          PayrollPayout.create!(
            organization: @organization, user: @user, period: @period, sent_by: @sent_by,
            **@payout.attributes.symbolize_keys.slice(:minutes, :hours, :hourly_wage, :amount, :tripletex_employee_id), **attributes
          )
        end
      end
      raise Error, message
    rescue ActiveRecord::RecordNotUnique
      Rails.logger.error(
        "Payroll::SendPayout: payout released mid-send and replaced by a new attempt; check both in Tripletex " \
        "(organization #{@organization.id}, user #{@user.id}, period #{@period.iso8601}, transaction #{@transaction_id || 'unknown'})"
      )
      refuse(:released_conflict)
    end

    def run_description
      month = I18n.l(@period, format: "%B %Y", locale: :nb).downcase # nb.yml capitalizes month names
      I18n.t("tripletex.payroll.run_description", month: month, locale: :nb)
    end
  end
end
