require "test_helper"

class Users::RegistrationsIntegrationTest < ActionDispatch::IntegrationTest
  test "should create user" do
    user_count = User.count

    post user_registration_path, params: {
      user: {
        locale: "en",
        first_name: "Test",
        last_name: "Name",
        email: "test@test",
        password: "123123",
        password_confirmation: "123123"
      }
    }

    assert_equal (user_count + 1), User.count
  end

  test "should not create bot user" do
    user_count = User.count

    post user_registration_path, params: {
      user: {
        locale: "en",
        first_name: "Test",
        last_name: "Name",
        email: "test@test",
        password: "123123",
        password_confirmation: "123123",
        honeypot_field: "bot data"
      }
    }

    assert_response :redirect
    assert_equal user_count, User.count
  end
end
