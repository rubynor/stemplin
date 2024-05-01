require "test_helper"
module  Workspace
  class TeamsControllerTest < ActionController::TestCase
    setup do
      @organization_admin = users(:organization_admin)

      sign_in @organization_admin
    end

    test "should get index" do
      get :index
      assert_response :success
    end

    test "should create a new user and associate with organization" do
      assert_difference("User.count") do
        assert_difference("AccessInfo.count") do
          post :create, params: {
            user: {
              email: "new_user@example.com",
              first_name: "John",
              last_name: "Doe",
              password: "password123",
              password_confirmation: "password123",
              role: :organization_user
            }
          }
        end
      end

      assert_response :success
    end
  end
end
