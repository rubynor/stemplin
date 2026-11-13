require "test_helper"

module Tripletex
  class ClientTest < ActiveSupport::TestCase
    FakeHttp = Struct.new(:responses, :requests, :start_options) do
      def request(request)
        requests << request
        response = responses.shift
        raise response if response.is_a?(Exception)

        response
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
      http.start_options = []
      original = Net::HTTP.method(:start)
      Net::HTTP.define_singleton_method(:start) { |*, **options, &block| http.start_options << options; block.call(http) }
      yield http
    ensure
      Net::HTTP.define_singleton_method(:start, original)
    end

    def session
      response(Net::HTTPOK, "200", { value: { token: "session-123" } })
    end

    def ok(body)
      response(Net::HTTPOK, "200", body)
    end

    def query(request)
      URI.decode_www_form(request.uri.query.to_s).to_h
    end

    def employment(start_date, end_date, *details)
      { startDate: start_date, endDate: end_date, employmentDetails: details.map { |date, type, wage| { date: date, remunerationType: type, hourlyWage: wage } } }
    end

    attr_reader :client

    # The session token is cached per client, so tests with several with_http blocks need a new client for each.
    def fresh_client
      Client.new(employee_token: "employee", consumer_token: "consumer", base_url: "https://api-test.tripletex.tech/v2")
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
        error = assert_raises(Tripletex::Error) { @client.company }
        assert_equal "Tripletex: Validering feilet. – customer: Kunden finnes ikke.", error.message
      end
    end

    test "needs Stemplin's consumer token" do
      client = Client.new(employee_token: "employee", consumer_token: nil)
      assert_raises(Tripletex::Error) { client.company }
    end

    test "employees lists active employees sorted by name" do
      with_http(session, ok({ values: [
        { id: 2, firstName: "Ola", lastName: "Nordmann", email: "ola@example.com", employeeNumber: "2" },
        { id: 1, firstName: "Kari", lastName: "Nordmann", email: nil, employeeNumber: "" }
      ] })) do |http|
        assert_equal [ 1, 2 ], client.employees.map { |e| e["id"] }

        request = http.requests.last
        assert_kind_of Net::HTTP::Get, request
        assert_equal "/v2/employee", request.uri.path
        assert_equal "false", query(request)["isInactive"]
        assert_equal "id,firstName,lastName,email,employeeNumber", query(request)["fields"]
      end
    end

    test "pay_details asks for every employee's employments in one request" do
      with_http(session, ok({ values: [
        { id: 7, employments: [ employment("2020-01-01", nil, [ "2020-01-01", "HOURLY_WAGE", 212.5 ]) ] },
        { id: 8, employments: [] }
      ] })) do |http|
        details = client.pay_details([ 7, 8, 9 ], on: Date.new(2026, 10, 31))

        assert_equal({ "remunerationType" => "HOURLY_WAGE", "hourlyWage" => BigDecimal("212.5") }, details[7])
        assert_kind_of BigDecimal, details[7]["hourlyWage"]
        assert_nil details[8]
        assert_nil details[9]

        request = http.requests.last
        assert_equal "/v2/employee", request.uri.path
        assert_equal "7,8,9", query(request)["id"]
        assert_includes query(request)["fields"], "employments(startDate,endDate,employmentDetails(date,remunerationType,hourlyWage))"
      end
    end

    test "pay_details picks the details row that applied on the given date" do
      # employment 2020-01-01..nil with details dated 2024-01-01 (hourlyWage 200),
      # 2026-06-01 (hourlyWage 250) and 2026-11-01 (hourlyWage 300)
      with_http(session, ok({ values: [ { id: 7, employments: [
        employment("2020-01-01", nil, [ "2026-11-01", "HOURLY_WAGE", 300.0 ], [ "2024-01-01", "HOURLY_WAGE", 200.0 ], [ "2026-06-01", "HOURLY_WAGE", 250.0 ])
      ] } ] })) do
        assert_equal BigDecimal("250"), client.pay_details([ 7 ], on: Date.new(2026, 10, 31))[7]["hourlyWage"]
      end
    end

    test "pay_details is nil when the only employment ended before the date" do
      with_http(session, ok({ values: [ { id: 7, employments: [
        employment("2020-01-01", "2026-09-30", [ "2020-01-01", "HOURLY_WAGE", 200.0 ])
      ] } ] })) do
        assert_nil client.pay_details([ 7 ], on: Date.new(2026, 10, 31))[7]
      end
    end

    test "pay_details finds an employment that ended during the month" do
      with_http(session, ok({ values: [ { id: 7, employments: [
        employment("2020-01-01", "2026-10-15", [ "2020-01-01", "HOURLY_WAGE", 200.0 ])
      ] } ] })) do
        assert_equal BigDecimal("200"), client.pay_details([ 7 ], on: Date.new(2026, 10, 31))[7]["hourlyWage"]
      end
    end

    test "pay_details finds an employment that ended on the first day of the month" do
      with_http(session, ok({ values: [ { id: 7, employments: [
        employment("2020-01-01", "2026-10-01", [ "2020-01-01", "HOURLY_WAGE", 200.0 ])
      ] } ] })) do
        assert_equal BigDecimal("200"), client.pay_details([ 7 ], on: Date.new(2026, 10, 31))[7]["hourlyWage"]
      end
    end

    test "pay_details finds an employment that started on the last day of the month" do
      with_http(session, ok({ values: [ { id: 7, employments: [
        employment("2026-10-31", nil, [ "2026-10-31", "HOURLY_WAGE", 200.0 ])
      ] } ] })) do
        assert_equal BigDecimal("200"), client.pay_details([ 7 ], on: Date.new(2026, 10, 31))[7]["hourlyWage"]
      end
    end

    test "pay_details is nil when the only employment starts after the month" do
      with_http(session, ok({ values: [ { id: 7, employments: [
        employment("2026-11-01", nil, [ "2026-11-01", "HOURLY_WAGE", 200.0 ])
      ] } ] })) do
        assert_nil client.pay_details([ 7 ], on: Date.new(2026, 10, 31))[7]
      end
    end

    test "pay_details ignores a later employment that has not started when the member left mid-month" do
      with_http(session, ok({ values: [ { id: 7, employments: [
        employment("2026-12-01", nil, [ "2026-12-01", "HOURLY_WAGE", 300.0 ]),
        employment("2020-01-01", "2026-10-15", [ "2020-01-01", "HOURLY_WAGE", 200.0 ])
      ] } ] })) do
        assert_equal BigDecimal("200"), client.pay_details([ 7 ], on: Date.new(2026, 10, 31))[7]["hourlyWage"]
      end
    end

    test "pay_details uses the latest employment when two overlap the month" do
      with_http(session, ok({ values: [ { id: 7, employments: [
        employment("2026-10-16", nil, [ "2026-10-16", "HOURLY_WAGE", 250.0 ]),
        employment("2020-01-01", "2026-10-15", [ "2020-01-01", "MONTHLY_WAGE", 0.0 ])
      ] } ] })) do
        assert_equal BigDecimal("250"), client.pay_details([ 7 ], on: Date.new(2026, 10, 31))[7]["hourlyWage"]
      end
    end

    test "pay_details uses the employment that covers the date when there are two" do
      # ended employment (MONTHLY_WAGE) and current one (HOURLY_WAGE, 250)
      with_http(session, ok({ values: [ { id: 7, employments: [
        employment("2020-01-01", "2026-05-31", [ "2020-01-01", "MONTHLY_WAGE", 0.0 ]),
        employment("2026-06-01", nil, [ "2026-06-01", "HOURLY_WAGE", 250.0 ])
      ] } ] })) do
        assert_equal "HOURLY_WAGE", client.pay_details([ 7 ], on: Date.new(2026, 10, 31))[7]["remunerationType"]
      end
    end

    test "pay_details skips an employment without a start date and details rows without a date" do
      with_http(session, ok({ values: [ { id: 7, employments: [
        employment(nil, nil, [ "2020-01-01", "MONTHLY_WAGE", 0.0 ]),
        employment("2020-01-01", nil, [ nil, "MONTHLY_WAGE", 0.0 ], [ "2026-06-01", "HOURLY_WAGE", 250.0 ])
      ] }, { id: 8, employments: [ employment(nil, nil, [ "2020-01-01", "HOURLY_WAGE", 250.0 ]) ] } ] })) do
        details = client.pay_details([ 7, 8 ], on: Date.new(2026, 10, 31))
        assert_equal({ "remunerationType" => "HOURLY_WAGE", "hourlyWage" => BigDecimal("250") }, details[7])
        assert_nil details[8]
      end
    end

    test "pay_details has a nil wage when Tripletex sends none" do
      with_http(session, ok({ values: [ { id: 7, employments: [ employment("2020-01-01", nil, [ "2020-01-01", "FEE", nil ]) ] } ] })) do
        assert_equal({ "remunerationType" => "FEE", "hourlyWage" => nil }, client.pay_details([ 7 ], on: Date.new(2026, 10, 31))[7])
      end
    end

    test "salary_types lists active salary types" do
      with_http(session, ok({ values: [ { id: 40018615, number: "2001", name: "Timelønn" } ] })) do |http|
        assert_equal [ { "id" => 40018615, "number" => "2001", "name" => "Timelønn" } ], client.salary_types

        request = http.requests.last
        assert_equal "/v2/salary/type", request.uri.path
        assert_equal "false", query(request)["isInactive"]
        assert_equal "id,number,name", query(request)["fields"]
      end
    end

    test "create_salary_run creates a run without default lines and returns its ids" do
      with_http(session, response(Net::HTTPCreated, "201", { value: { id: 5377193, payslips: [ { id: 24486093 } ] } })) do |http|
        result = client.create_salary_run(employee_id: 7, year: 2026, month: 10, date: Date.new(2026, 11, 11), description: "Stemplin oktober")

        assert_equal({ "transaction_id" => 5377193, "payslip_id" => 24486093 }, result)

        request = http.requests.last
        assert_kind_of Net::HTTP::Post, request
        assert_equal "/v2/salary/transaction/:createSalaryRun", request.uri.path
        assert_equal({ "year" => "2026", "month" => "10", "date" => "2026-11-11", "description" => "Stemplin oktober", "addDefaultSpecifications" => "false" }, query(request))
        assert_equal [ 7 ], JSON.parse(request.body)
      end
    end

    test "add_salary_line adds a line to the payslip" do
      with_http(session, ok({ value: { id: 158138811, amount: 3082.5 } })) do |http|
        assert_nil client.add_salary_line(transaction_id: 5377193, payslip_id: 24486093, salary_type_id: 40018615, rate: BigDecimal("250"), count: 12.33)

        request = http.requests.last
        assert_kind_of Net::HTTP::Put, request
        assert_equal "/v2/salary/transaction/5377193/:addSpecification", request.uri.path
        assert_equal({ "payslip" => { "id" => 24486093 }, "salaryType" => { "id" => 40018615 }, "rate" => 250.0, "count" => 12.33 }, JSON.parse(request.body))
      end
    end

    test "delete_salary_run deletes the run" do
      no_content = Net::HTTPNoContent.new("1.1", "204", "").tap { |r| r.instance_variable_set(:@body, ""); r.instance_variable_set(:@read, true) }
      with_http(session, no_content) do |http|
        assert_nil client.delete_salary_run(5377193)

        request = http.requests.last
        assert_kind_of Net::HTTP::Delete, request
        assert_equal "/v2/salary/transaction/5377193", request.uri.path
      end
    end

    test "a timeout on a write raises UncertainError" do
      with_http(session, Net::ReadTimeout.new) do
        assert_raises(Tripletex::UncertainError) { client.create_salary_run(employee_id: 7, year: 2026, month: 11, date: Date.new(2026, 11, 11), description: "x") }
      end
    end

    test "a write failing mid-request raises UncertainError" do
      [ Errno::ECONNRESET, EOFError, Net::HTTPBadResponse ].each do |failure|
        with_http(session, failure.new) do
          assert_raises(Tripletex::UncertainError, failure.name) { fresh_client.add_salary_line(transaction_id: 1, payslip_id: 2, salary_type_id: 3, rate: 1, count: 1) }
        end
        with_http(session, failure.new) do
          assert_raises(Tripletex::UncertainError, failure.name) { fresh_client.delete_salary_run(1) }
        end
      end
    end

    test "a session creation timeout stays a plain error" do
      with_http(Net::ReadTimeout.new) do
        error = assert_raises(Tripletex::Error) { fresh_client.delete_salary_run(1) }
        assert_not_kind_of Tripletex::UncertainError, error
      end
    end

    test "a 5xx on a write raises UncertainError, on a read a plain error, a 4xx stays plain" do
      with_http(session, response(Net::HTTPInternalServerError, "500", { message: "boom" })) do
        assert_raises(Tripletex::UncertainError) { fresh_client.delete_salary_run(1) }
      end
      with_http(session, response(Net::HTTPBadGateway, "502", {})) do
        assert_raises(Tripletex::UncertainError) { fresh_client.add_salary_line(transaction_id: 1, payslip_id: 2, salary_type_id: 3, rate: 1, count: 1) }
      end
      with_http(session, response(Net::HTTPInternalServerError, "500", { message: "boom" })) do
        error = assert_raises(Tripletex::Error) { fresh_client.salary_types }
        assert_not_kind_of Tripletex::UncertainError, error
      end
      with_http(session, response(Net::HTTPUnprocessableEntity, "422", { message: "no" })) do
        error = assert_raises(Tripletex::Error) { fresh_client.delete_salary_run(1) }
        assert_not_kind_of Tripletex::UncertainError, error
      end
    end

    test "Net::HTTP is told never to retry a request" do
      with_http(session, ok({ values: [] })) do |http|
        client.salary_types
        assert_equal [ 0, 0 ], http.start_options.map { |options| options[:max_retries] }
      end
    end

    test "every request is bounded by open, read and write timeouts" do
      with_http(session, ok({ values: [] })) do |http|
        client.salary_types
        assert_equal [ [ 5, 30, 30 ] ] * 2, http.start_options.map { |options| options.values_at(:open_timeout, :read_timeout, :write_timeout) }
      end
    end

    test "create_salary_run raises UncertainError when the response lacks ids" do
      [ {}, { value: { id: 1 } }, { value: { id: 1, payslips: [] } }, { value: { payslips: [ { id: 2 } ] } } ].each do |body|
        with_http(session, response(Net::HTTPCreated, "201", body)) do
          assert_raises(Tripletex::UncertainError) { fresh_client.create_salary_run(employee_id: 7, year: 2026, month: 10, date: Date.new(2026, 11, 11), description: "x") }
        end
      end
    end

    test "a timeout on a read stays a plain error" do
      with_http(session, Net::ReadTimeout.new) do
        error = assert_raises(Tripletex::Error) { client.salary_types }
        assert_not_kind_of Tripletex::UncertainError, error
      end
    end

    test "a write that never connected stays a plain error" do
      original = Net::HTTP.method(:start)
      Net::HTTP.define_singleton_method(:start) { |*, **| raise Errno::ECONNREFUSED }
      client.instance_variable_set(:@session_token, "session-123")

      error = assert_raises(Tripletex::Error) { client.delete_salary_run(1) }
      assert_not_kind_of Tripletex::UncertainError, error
    ensure
      Net::HTTP.define_singleton_method(:start, original)
    end

    test "a 403 on a salary call raises AccessError" do
      with_http(session, response(Net::HTTPForbidden, "403", { message: "Forbidden" })) do
        error = assert_raises(Tripletex::AccessError) { client.salary_types }
        assert_equal I18n.t("tripletex.errors.salary_access"), error.message
      end
    end

    test "a 401 when reading pay details raises AccessError" do
      with_http(session, response(Net::HTTPUnauthorized, "401", { message: "Unauthorized" })) do
        assert_raises(Tripletex::AccessError) { client.pay_details([ 7 ], on: Date.new(2026, 10, 31)) }
      end
    end

    test "a 403 outside salary keeps the invalid key message" do
      with_http(session, response(Net::HTTPForbidden, "403", { message: "Forbidden" })) do
        error = assert_raises(Tripletex::Error) { client.employees }
        assert_not_kind_of Tripletex::AccessError, error
        assert_equal I18n.t("tripletex.errors.invalid_token"), error.message
      end
    end

    test "staging uses the Tripletex test environment unless TRIPLETEX_BASE_URL is set" do
      original = ENV.delete("TRIPLETEX_BASE_URL")
      staging = ActiveSupport::EnvironmentInquirer.new("staging")
      production = ActiveSupport::EnvironmentInquirer.new("production")

      assert_equal "https://api-test.tripletex.tech/v2", Client.default_base_url(staging)
      assert_equal "https://tripletex.no/v2", Client.default_base_url(production)

      ENV["TRIPLETEX_BASE_URL"] = "https://example.test/v2"
      assert_equal "https://example.test/v2", Client.default_base_url(staging)
    ensure
      original ? ENV["TRIPLETEX_BASE_URL"] = original : ENV.delete("TRIPLETEX_BASE_URL")
    end
  end
end
