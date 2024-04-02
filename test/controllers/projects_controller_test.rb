require "test_helper"

class ProjectsControllerTest < ActionController::TestCase
  def setup
    @user = users(:joe)
    @admin = users(:ron)
  end

  test "should redirect non-admin users" do
    sign_in @user

    get :new
    assert_redirected_to root_path
  end

  test "should not redirect admin users" do
   sign_in @admin

   get :new
   assert_response :ok
  end
end
