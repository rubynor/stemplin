# frozen_string_literal: true

Rack::Attack.throttle("oauth/register", limit: 10, period: 1.hour) do |req|
  req.ip if req.path == "/oauth/register" && req.post?
end

Rack::Attack.throttle("oauth/token", limit: 30, period: 1.minute) do |req|
  req.ip if req.path == "/oauth/token" && req.post?
end

RETRY_AFTER_SECONDS = {
  "oauth/register" => "3600",
  "oauth/token" => "60"
}.freeze

Rack::Attack.throttled_responder = lambda do |request|
  matched = request.env["rack.attack.matched"]
  retry_after = RETRY_AFTER_SECONDS[matched] || "60"

  [
    429,
    { "Content-Type" => "application/json", "Retry-After" => retry_after },
    [ '{"error":"too_many_requests","error_description":"Rate limit exceeded. Try again later."}' ]
  ]
end
