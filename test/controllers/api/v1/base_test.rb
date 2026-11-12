require "test_helper"

class Api::V1::BaseTest < ActionDispatch::IntegrationTest
  fixtures :all

  private

  def api_headers(user, organization: nil)
    token = user.api_tokens.create!(name: "Test").plaintext
    headers = { "Authorization" => "Bearer #{token}" }
    headers["X-Organization-Id"] = organization.id.to_s if organization
    headers
  end

  def json_response
    JSON.parse(response.body)
  end
end
