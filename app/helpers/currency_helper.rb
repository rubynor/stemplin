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
end
