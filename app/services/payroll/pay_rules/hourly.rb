module Payroll
  module PayRules
    class Hourly
      attr_reader :rate

      # Nil unless the employee has a positive hourly wage.
      def self.for(pay)
        wage = pay["hourlyWage"]
        new(pay) if wage && wage.to_d.positive?
      end

      def initialize(pay)
        @rate = pay["hourlyWage"].to_d
      end

      def count(minutes)
        (minutes / 60.0).round(2).to_d
      end

      def amount(minutes)
        (count(minutes) * rate).round(2)
      end
    end
  end
end
