class ConvertKroneOre
  extend ActionView::Helpers::NumberHelper

  def self.in(number)
    case number
    when String
      (string_to_decimal(number.gsub(" ", "")) * 100).to_i
    else
      (number * 100).to_i
    end
  end

  def self.out(number)
    number_to_currency(number.to_d / 100, locale: :nb)
  end

  def self.string_to_decimal(str)
    str.gsub(",", ".").to_d
  end
end
