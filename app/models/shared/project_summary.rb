module Shared
  class ProjectSummary
    attr_reader :project, :time_regs

    def initialize(project:, time_regs:)
      @project = project
      @time_regs = time_regs
    end

    def owner
      project.organization
    end

    def currency
      owner.currency
    end

    def total_minutes
      @total_minutes ||= time_regs.sum(&:minutes)
    end

    def total_amount
      @total_amount ||= time_regs.sum { |time_reg| amount_for(time_reg) }
    end

    def amount_for(time_reg)
      project.billable ? time_reg.billed_amount : 0
    end
  end
end
