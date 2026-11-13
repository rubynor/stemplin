require "test_helper"

class Payroll::PayRulesTest < ActiveSupport::TestCase
  test "125 minutes at 250.00 is 2.08 hours and 520.00" do
    rule = Payroll::PayRules.for("remunerationType" => "HOURLY_WAGE", "hourlyWage" => BigDecimal("250"))
    assert_equal BigDecimal("2.08"), rule.count(125)
    assert_equal BigDecimal("520.00"), rule.amount(125)
    assert_equal BigDecimal("250"), rule.rate
  end

  test "monthly wage, missing wage and nil pay have no rule" do
    assert_nil Payroll::PayRules.for("remunerationType" => "MONTHLY_WAGE", "hourlyWage" => nil)
    assert_nil Payroll::PayRules.for("remunerationType" => "HOURLY_WAGE", "hourlyWage" => nil)
    assert_nil Payroll::PayRules.for(nil)
  end

  test "a zero wage has no rule" do
    assert_nil Payroll::PayRules.for("remunerationType" => "HOURLY_WAGE", "hourlyWage" => BigDecimal("0"))
  end
end
