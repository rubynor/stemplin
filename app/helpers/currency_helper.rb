module CurrencyHelper
  def currency_title(currency)
    Stemplin.config.currencies[currency.to_sym][:title]
  end

  def currency_symbol(currency)
    Stemplin.config.currencies[currency.to_sym][:entity].html_safe
  end

  def currency_title_and_code(currency)
    "#{currency_title(currency)} - #{currency}"
  end

  def for_select(currencies)
    currencies.map { |code| [currency_title_and_code(code), code] }
  end
end
