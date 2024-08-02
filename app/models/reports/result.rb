module Reports
  class Result
    def initialize(time_regs:, filter:)
      @time_regs = time_regs
      @filter = filter
    end

    def grouped
      @grouped ||= group_time_regs
    end

    private

    def group_time_regs
      case @filter.category
      when Reports::Filter::CLIENTS
        group_by(attribute: Reports::Filter::CLIENTS)
      when Reports::Filter::PROJECTS
        group_by(attribute: Reports::Filter::PROJECTS)
      when Reports::Filter::USERS
        group_by(attribute: Reports::Filter::USERS)
      when Reports::Filter::TASKS
        group_by(attribute: Reports::Filter::TASKS)
      else
        group_by(attribute: Reports::Filter::CLIENTS)
      end
    end

    def group_by(attribute:, attribute_name_method: :name)
      singular_attribute = attribute.singularize.to_sym
      @time_regs.group_by(&singular_attribute).map do |group, time_regs|
        billable_time_regs = time_regs.select(&method(:project_billable?))
        total_minutes = time_regs.sum(&:minutes)
        total_billable_minutes = billable_time_regs.sum(&:minutes)
        total_billable_minutes_percentage = total_minutes.zero? ? 0.00 : (total_billable_minutes / total_minutes.to_f * 100).truncate(2)

        {
          attribute_name: group.send(attribute_name_method),
          total_minutes: total_minutes,
          total_billable_minutes: total_billable_minutes,
          total_billable_amount: ConvertKroneOre.out(billable_time_regs.sum(&:billed_amount)),
          total_billable_minutes_percentage: total_billable_minutes_percentage,
          group_link: { "#{singular_attribute}_ids": [ group.id ], category: nil }
        }
      end
    end

    def project_billable?(time_reg)
      time_reg.project.billable
    end
  end
end
