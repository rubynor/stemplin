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

  attr_reader :orders

  def initialize(company: { "id" => 42, "name" => "Firma AS" }, customers: [], error: nil)
    @company = company
    @customers = customers
    @error = error
    @orders = []
  end

  def company
    raise Tripletex::Error, @error if @error
    @company
  end

  def customers
    raise Tripletex::Error, @error if @error
    @customers
  end

  def create_order(attributes)
    raise Tripletex::Error, @error if @error
    @orders << attributes
    1000 + @orders.size
  end
end

TripletexIntegration.prepend(FakeTripletexApi::Hook)
