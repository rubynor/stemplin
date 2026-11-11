require "net/http"

module Tripletex
  # Thin wrapper around the Tripletex v2 REST API.
  # Auth: a consumer token (Stemplin's, from ENV) and an employee token (the workspace's) are
  # exchanged for a session token, which is sent as the password in Basic auth with user "0".
  class Client
    DEFAULT_BASE_URL = "https://tripletex.no/v2".freeze
    PAGE_SIZE = 1000
    SALARY_PATHS = %w[/salary/ /employee/employment].freeze

    def initialize(employee_token:, consumer_token: ENV["TRIPLETEX_CONSUMER_TOKEN"], base_url: ENV.fetch("TRIPLETEX_BASE_URL", DEFAULT_BASE_URL))
      @employee_token = employee_token
      @consumer_token = consumer_token
      @base_url = base_url.chomp("/")
    end

    def self.configured?
      ENV["TRIPLETEX_CONSUMER_TOKEN"].present?
    end

    # => { "id" => 123, "name" => "Firma AS" }
    def company
      get("/token/session/%3EwhoAmI", fields: "company(id,name)").dig("value", "company")
    end

    # Active employees, sorted by name.
    # => [{ "id" => 7, "firstName" => "Kari", "lastName" => "Nordmann", "email" => "...", "employeeNumber" => "1" }]
    def employees
      get("/employee", isInactive: false, fields: "id,firstName,lastName,email,employeeNumber", count: PAGE_SIZE)["values"]
        .sort_by { |employee| [ employee["firstName"].to_s.downcase, employee["lastName"].to_s.downcase ] }
    end

    # What each employee is paid on the given date, from the employment that covers it and the latest
    # details row dated on or before it. nil when no employment covers the date.
    # One request: employments are nested on /employee (the unfiltered /employee/employment list is incomplete).
    # => { 7 => { "remunerationType" => "HOURLY_WAGE", "hourlyWage" => BigDecimal("250") }, 8 => nil }
    def pay_details(employee_ids, on:)
      return {} if employee_ids.empty?

      employees = request(Net::HTTP::Get, "/employee", {
        id: employee_ids.join(","),
        fields: "id,employments(startDate,endDate,employmentDetails(date,remunerationType,hourlyWage))",
        count: PAGE_SIZE
      }, salary: true)["values"].index_by { |employee| employee["id"] }

      employee_ids.index_with { |id| pay_details_on(employees[id], on) }
    end

    # Active salary types. => [{ "id" => 40018615, "number" => "2001", "name" => "Timelønn" }]
    def salary_types
      get("/salary/type", isInactive: false, fields: "id,number,name", count: PAGE_SIZE)["values"]
    end

    # Creates an open salary run with one payslip for the employee and no default lines (Tripletex still
    # adds its tax deduction line). => { "transaction_id" => 5377193, "payslip_id" => 24486093 }
    def create_salary_run(employee_id:, year:, month:, date:, description:)
      run = request(Net::HTTP::Post, "/salary/transaction/:createSalaryRun", {
        year: year, month: month, date: date.iso8601, description: description, addDefaultSpecifications: false
      }, body: [ employee_id ])["value"]

      transaction_id = run.is_a?(Hash) ? run["id"] : nil
      payslip_id = run.is_a?(Hash) ? run.dig("payslips", 0, "id") : nil
      if transaction_id.nil? || payslip_id.nil?
        raise UncertainError, I18n.t("tripletex.errors.uncertain", message: "response without transaction or payslip id")
      end

      { "transaction_id" => transaction_id, "payslip_id" => payslip_id }
    end

    # Tripletex computes the line amount as rate × count.
    def add_salary_line(transaction_id:, payslip_id:, salary_type_id:, rate:, count:)
      request(Net::HTTP::Put, "/salary/transaction/#{transaction_id}/:addSpecification", {}, body: {
        payslip: { id: payslip_id }, salaryType: { id: salary_type_id }, rate: rate.to_f, count: count.to_f
      })
      nil
    end

    def delete_salary_run(transaction_id)
      request(Net::HTTP::Delete, "/salary/transaction/#{transaction_id}", {})
      nil
    end

    private

    def session_token
      @session_token ||= begin
        raise Error, I18n.t("tripletex.errors.not_configured") if @consumer_token.blank?

        response = request(Net::HTTP::Put, "/token/session/:create", {
          consumerToken: @consumer_token,
          employeeToken: @employee_token,
          expirationDate: Date.tomorrow.iso8601
        }, authenticate: false)
        response.dig("value", "token")
      end
    end

    def pay_details_on(employee, on)
      employment = Array(employee&.dig("employments")).find do |e|
        Date.parse(e["startDate"]) <= on && (e["endDate"].blank? || Date.parse(e["endDate"]) >= on)
      end
      details = Array(employment&.dig("employmentDetails"))
        .select { |d| d["date"].present? && Date.parse(d["date"]) <= on }
        .max_by { |d| Date.parse(d["date"]) }
      return unless details

      wage = details["hourlyWage"]
      { "remunerationType" => details["remunerationType"], "hourlyWage" => wage.nil? ? nil : BigDecimal(wage.to_s) }
    end

    def get(path, params = {})
      request(Net::HTTP::Get, path, params)
    end

    # salary: a 401/403 means the key lacks salary access (true by default for salary and employment paths).
    def request(method, path, params, body: nil, authenticate: true, salary: path.start_with?(*SALARY_PATHS))
      uri = URI("#{@base_url}#{path}")
      uri.query = URI.encode_www_form(params) if params.any?

      request = method.new(uri)
      request["Accept"] = "application/json"
      request.basic_auth("0", session_token) if authenticate
      if body
        request["Content-Type"] = "application/json"
        request.body = body.to_json
      end

      write = authenticate && method != Net::HTTP::Get
      sent = false
      begin
        # max_retries: 0 stops Net::HTTP replaying PUT/DELETE by itself; a write is never sent twice.
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 30, max_retries: 0) do |http|
          sent = true # connected; from here on the request may reach Tripletex
          http.request(request)
        end
      rescue StandardError => e
        if sent && write
          raise UncertainError, I18n.t("tripletex.errors.uncertain", message: e.message)
        end

        raise Error, I18n.t("tripletex.errors.unreachable", message: e.message)
      end

      parsed = parse(response.body)
      if response.code.in?(%w[401 403]) && salary
        raise AccessError, I18n.t("tripletex.errors.salary_access")
      end
      if write && response.code.start_with?("5")
        raise UncertainError, I18n.t("tripletex.errors.uncertain", message: error_message(response, parsed))
      end
      raise Error, error_message(response, parsed) unless response.is_a?(Net::HTTPSuccess)

      parsed
    end

    def parse(body)
      body.present? ? JSON.parse(body) : {}
    rescue JSON::ParserError
      {}
    end

    def error_message(response, parsed)
      return I18n.t("tripletex.errors.invalid_token") if response.code.in?(%w[401 403])

      details = Array(parsed["validationMessages"]).filter_map { |m| [ m["field"], m["message"] ].compact.join(": ").presence }
      message = parsed["message"].presence || "#{response.code} #{response.message}"

      [ "Tripletex: #{message}", *details ].join(" – ")
    end
  end
end
