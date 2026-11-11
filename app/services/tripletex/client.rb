require "net/http"

module Tripletex
  # Thin wrapper around the Tripletex v2 REST API.
  # Auth: a consumer token (Stemplin's, from ENV) and an employee token (the workspace's) are
  # exchanged for a session token, which is sent as the password in Basic auth with user "0".
  class Client
    DEFAULT_BASE_URL = "https://tripletex.no/v2".freeze
    PAGE_SIZE = 1000

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

    # => [{ "id" => 1, "name" => "Kunde AS", "customerNumber" => 10001 }, ...]
    def customers
      customers = []
      loop do
        page = get("/customer", isInactive: false, fields: "id,name,customerNumber", from: customers.size, count: PAGE_SIZE)
        customers.concat(page["values"])
        break if page["values"].size < PAGE_SIZE || customers.size >= page["fullResultSize"].to_i
      end
      customers.sort_by { |customer| customer["name"].to_s.downcase }
    end

    # Returns the id of the created order.
    def create_order(attributes)
      post("/order", attributes).dig("value", "id")
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

    def get(path, params = {})
      request(Net::HTTP::Get, path, params)
    end

    def post(path, body)
      request(Net::HTTP::Post, path, {}, body: body)
    end

    def request(method, path, params, body: nil, authenticate: true)
      uri = URI("#{@base_url}#{path}")
      uri.query = URI.encode_www_form(params) if params.any?

      request = method.new(uri)
      request["Accept"] = "application/json"
      request.basic_auth("0", session_token) if authenticate
      if body
        request["Content-Type"] = "application/json"
        request.body = body.to_json
      end

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 20) do |http|
        http.request(request)
      end
      parsed = parse(response.body)
      raise Error, error_message(response, parsed) unless response.is_a?(Net::HTTPSuccess)

      parsed
    rescue Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError => e
      raise Error, I18n.t("tripletex.errors.unreachable", message: e.message)
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
