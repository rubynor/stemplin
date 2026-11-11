module PayrollHelper
  # Whole currency units (not hundredths) in the format used in the reports, e.g. "1 234,50".
  def payroll_money(amount)
    ConvertCurrencyHundredths.out(amount * 100)
  end

  def payroll_hours(hours)
    number_with_precision(hours, precision: 2)
  end

  def payroll_month_param(date)
    date.strftime("%Y-%m")
  end
end
