module Reports
  class Summary
    def initialize(time_regs:, organization: nil)
      @time_regs = time_regs
      @organization = organization
    end

    def total_billable_amount
      @total_billable_amount ||= if @organization
        @time_regs.billable.sum { |tr| tr.billed_amount_for(@organization) }
      else
        @time_regs.billable.sum(&:billed_amount)
      end
    end

    def total_billable_amount_currency
      ConvertCurrencyHundredths.out(total_billable_amount)
    end

    def total_minutes
      @total_minutes ||= @time_regs.sum(&:minutes)
    end

    def total_billable_minutes
      @total_billable_minutes ||= @time_regs.billable.sum(&:minutes)
    end

    def total_non_billable_minutes
      total_minutes - total_billable_minutes
    end
  end
end
