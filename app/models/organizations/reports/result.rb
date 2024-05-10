module Organizations
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
        when Organizations::Reports::Filter::CLIENTS
          group_by(attribute: :client, attribute_name_method: :name)
        when Organizations::Reports::Filter::PROJECTS
          group_by(attribute: :project, attribute_name_method: :name)
        when Organizations::Reports::Filter::TEAM_MEMBERS
          group_by(attribute: :user, attribute_name_method: :name)
        when Organizations::Reports::Filter::TASKS
          group_by(attribute: :task, attribute_name_method: :name)
        else
          group_by(attribute: :client, attribute_name_method: :name)
        end
      end

      def group_by(attribute:, attribute_name_method:)
        @time_regs.group_by(&attribute).map do |group, time_regs|
          billable_time_regs = time_regs.select(&method(:project_billable?))
          total_minutes = time_regs.sum(&:minutes)
          total_billable_minutes = billable_time_regs.sum(&:minutes)

          {
            attribute_name: group.send(attribute_name_method),
            total_minutes: total_minutes,
            total_billable_minutes: total_billable_minutes,
            total_billable_amount: ConvertKroneOre.out(billable_time_regs.sum(&:billed_amount)),
            total_billable_minutes_percentage: (total_billable_minutes / total_minutes.to_f * 100).truncate(2)
          }
        end
      end

      def project_billable?(time_reg)
        time_reg.project.billable
      end
    end
  end
end
