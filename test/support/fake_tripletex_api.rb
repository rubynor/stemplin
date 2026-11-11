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

  attr_reader :orders, :attachments

  def initialize(company: { "id" => 42, "name" => "Firma AS" }, customers: [], error: nil, attach_error: nil)
    @company = company
    @customers = customers
    @error = error
    @attach_error = attach_error
    @orders = []
    @attachments = []
  end

  def company
    raise Tripletex::Error, @error if @error
    @company
  end

  def customers
    raise Tripletex::Error, @error if @error
    @customers
  end

  def vat_type_id(number)
    raise Tripletex::Error, @error if @error
    { "3" => 3 }.fetch(number)
  end

  def create_order(attributes)
    raise Tripletex::Error, @error if @error
    @orders << attributes
    1000 + @orders.size
  end

  def attach_to_order(order_id, filename:, data:, add_to_invoice_mode: "NEXT")
    raise Tripletex::Error, @attach_error if @attach_error
    @attachments << { order_id: order_id, filename: filename, data: data, add_to_invoice_mode: add_to_invoice_mode }
    {}
  end
end

TripletexIntegration.prepend(FakeTripletexApi::Hook)
