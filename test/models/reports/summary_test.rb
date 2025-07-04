require "test_helper"

module Reports
  class SummaryTest < ActiveSupport::TestCase
    def setup
      @time_regs = TimeReg.between_dates(1.week.ago, Date.today + 1.day)
      @summary = Reports::Summary.new(time_regs: @time_regs)
    end

    test "#total_billable_amount returns the sum of all billable time_regs" do
      assert_equal @time_regs.billable.sum(&:billed_amount), @summary.total_billable_amount
    end

    test "#total_billable_amount_currency returns the sum of all billable time_regs, converted back from hundredths to decimal number" do
      assert_equal ConvertCurrencyHundredths.out(@time_regs.billable.sum(&:billed_amount)), @summary.total_billable_amount_currency
    end

    test "#total_minutes returns the sum of all time_regs minutes" do
      assert_equal @time_regs.sum(&:minutes), @summary.total_minutes
    end

    test "#total_billable_minutes returns the sum of all billable time_regs minutes" do
      assert_equal @time_regs.billable.sum(&:minutes), @summary.total_billable_minutes
    end

    test "#total_non_billable_minutes returns the sum of all non-billable time_regs minutes" do
      assert_equal @summary.total_minutes - @summary.total_billable_minutes, @summary.total_non_billable_minutes
    end
  end
end
