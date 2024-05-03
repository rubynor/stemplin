module RateConvertible
  extend ActiveSupport::Concern

  included do
    def rate_nok
      ConvertKroneOre.out(rate)
    end

    def rate_nok=(rate_in_nok)
      self.rate = ConvertKroneOre.in(rate_in_nok)
    end
  end
end
