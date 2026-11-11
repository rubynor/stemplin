require "test_helper"

module Tripletex
  class ClientTest < ActiveSupport::TestCase
    FakeHttp = Struct.new(:responses, :requests) do
      def request(request)
        requests << request
        responses.shift
      end
    end

    def response(klass, code, body)
      klass.new("1.1", code, "").tap do |response|
        response.instance_variable_set(:@body, body.to_json)
        response.instance_variable_set(:@read, true)
      end
    end

    # Net::HTTP.start is swapped for the duration of the block; requests are captured in order.
    def with_http(*responses)
      http = FakeHttp.new(responses, [])
      original = Net::HTTP.method(:start)
      Net::HTTP.define_singleton_method(:start) { |*, **, &block| block.call(http) }
      yield http
    ensure
      Net::HTTP.define_singleton_method(:start, original)
    end

    setup do
      @client = Client.new(employee_token: "employee", consumer_token: "consumer", base_url: "https://api-test.tripletex.tech/v2")
    end

    test "opens a session and authenticates with it" do
      with_http(
        response(Net::HTTPOK, "200", { value: { token: "session-123" } }),
        response(Net::HTTPOK, "200", { value: { company: { id: 7, name: "Firma AS" } } })
      ) do |http|
        assert_equal({ "id" => 7, "name" => "Firma AS" }, @client.company)

        session, whoami = http.requests
        assert_kind_of Net::HTTP::Put, session
        assert_includes session.path, "consumerToken=consumer"
        assert_includes session.path, "employeeToken=employee"
        assert_equal "Basic #{Base64.strict_encode64('0:session-123')}", whoami["Authorization"]
      end
    end

    test "posts orders as json" do
      with_http(
        response(Net::HTTPOK, "200", { value: { token: "session-123" } }),
        response(Net::HTTPCreated, "201", { value: { id: 99 } })
      ) do |http|
        assert_equal 99, @client.create_order(customer: { id: 1 }, orderLines: [])
        assert_equal({ "customer" => { "id" => 1 }, "orderLines" => [] }, JSON.parse(http.requests.last.body))
      end
    end

    test "uploads attachments as multipart for the next invoice" do
      with_http(
        response(Net::HTTPOK, "200", { value: { token: "session-123" } }),
        response(Net::HTTPOK, "200", {})
      ) do |http|
        @client.attach_to_order(99, filename: "rapport.pdf", data: "%PDF-1.4 test")

        upload = http.requests.last
        assert_kind_of Net::HTTP::Put, upload
        assert_equal "/v2/order/99/:attach?addToInvoiceMode=NEXT", upload.path
        assert_equal "Basic #{Base64.strict_encode64('0:session-123')}", upload["Authorization"]
      end
    end

    test "reports a rejected token in plain words" do
      with_http(response(Net::HTTPForbidden, "403", { message: "Forbidden" })) do
        error = assert_raises(Tripletex::Error) { @client.company }
        assert_equal I18n.t("tripletex.errors.invalid_token"), error.message
      end
    end

    test "includes validation messages from Tripletex" do
      with_http(
        response(Net::HTTPOK, "200", { value: { token: "session-123" } }),
        response(Net::HTTPUnprocessableEntity, "422", { message: "Validering feilet.", validationMessages: [ { field: "customer", message: "Kunden finnes ikke." } ] })
      ) do
        error = assert_raises(Tripletex::Error) { @client.create_order({}) }
        assert_equal "Tripletex: Validering feilet. – customer: Kunden finnes ikke.", error.message
      end
    end

    test "needs Stemplin's consumer token" do
      client = Client.new(employee_token: "employee", consumer_token: nil)
      assert_raises(Tripletex::Error) { client.company }
    end
  end
end
