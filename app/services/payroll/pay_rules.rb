module Payroll
  # Picks the rule that turns minutes into hours and an amount, from how
  # Tripletex says the employee is paid. A new pay type is one new entry.
  module PayRules
    REGISTRY = { "HOURLY_WAGE" => Hourly }.freeze

    # pay is a value from Tripletex::Client#pay_details. Nil when no rule applies.
    def self.for(pay)
      return if pay.nil?

      REGISTRY[pay["remunerationType"]]&.for(pay)
    end
  end
end
