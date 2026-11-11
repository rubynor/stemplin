# Stands in for Tripletex::Client in tests. Install it with `FakeTripletexApi.install(fake)`;
# every TripletexIntegration#api then returns it until `FakeTripletexApi.reset`.
class FakeTripletexApi
  module Hook
    def api = FakeTripletexApi.current || super
  end

  class << self
    attr_accessor :current

    def install(fake = new) = self.current = fake
    def reset = self.current = nil
  end

  def initialize(company: { "id" => 42, "name" => "Firma AS" }, error: nil)
    @company = company
    @error = error
  end

  def company
    raise Tripletex::Error, @error if @error
    @company
  end
end

TripletexIntegration.prepend(FakeTripletexApi::Hook)
