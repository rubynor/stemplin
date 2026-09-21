require "test_helper"

class SpectatorSignInTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "spectator is redirected from root to reports and the page renders" do
    sign_in users(:organization_spectator)

    get root_path
    assert_redirected_to reports_path

    follow_redirect!
    assert_response :success
  end
end
