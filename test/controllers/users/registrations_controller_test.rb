require "test_helper"

class Users::RegistrationsControllerTest < ActionController::TestCase
  def setup
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = users(:ron)
    sign_in @user
  end

  test "the old edit address leads to the profile" do
    get :edit

    assert_redirected_to profile_path
  end

  test "the old combined update leads to the profile without changing the account" do
    put :update, params: { user: { first_name: "Rob", email: "new@example.com", current_password: "password" } }

    assert_redirected_to profile_path
    assert_equal "Ron", @user.reload.first_name
    assert_equal "ron@example.com", @user.email
  end
end
