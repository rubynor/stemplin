module Organizations
  module Reports
    class Summary
    def initialize(time_regs:)
      @time_regs = time_regs
    end

    def total_billable_amount
      @total_billable_amount ||= @time_regs.billable.sum(&:billed_amount)
    end

    def total_billable_amount_nok
      ConvertKroneOre.out(total_billable_amount)
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
end
