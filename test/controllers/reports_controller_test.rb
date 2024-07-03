require "test_helper"

class ReportsControllerTest < ActionController::TestCase
  setup do
    @user = users(:organization_user)
    sign_in @user
  end

  test "should get index" do
    get :show
    assert_response :success
  end

  test "spectator should get index" do
    sign_in users(:organization_spectator)
    get :show
    assert_response :success
  end
end
