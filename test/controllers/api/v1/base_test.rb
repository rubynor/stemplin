require "test_helper"

class Api::V1::BaseTest < ActionDispatch::IntegrationTest
  fixtures :all

  private

  def api_headers(user)
    user.regenerate_api_token unless user.api_token
    { "Authorization" => "Bearer #{user.api_token}" }
  end

  def json_response
    JSON.parse(response.body)
  end
end
