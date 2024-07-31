class ConvertCurrencyHundredths
  extend ActionView::Helpers::NumberHelper

  # We store money sums as integers hundredths of the currency unit in the database (e.g. 250 for 2.5 NOK)
  # This helper converts between the integer and the decimal representation

  def self.in(number)
    case number
    when String
      (string_to_decimal(number.gsub(" ", "")) * 100).to_i
    else
      (number * 100).to_i
    end
  end

  def self.out(number)
    number_to_currency(number.to_d / 100, unit: "", separator: ",", delimiter: " ")
  end

  def self.string_to_decimal(str)
    str.gsub(",", ".").to_d
  end
end
