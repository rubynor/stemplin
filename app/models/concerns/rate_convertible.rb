module RateConvertible
  extend ActiveSupport::Concern

  included do
    def rate_currency
      ConvertCurrencyHundredths.out(rate)
    end

    def rate_currency=(rate_in_currency)
      self.rate = ConvertCurrencyHundredths.in(rate_in_currency)
    end
  end
end
