require "test_helper"

class Users::RegistrationsControllerTest < ActionController::TestCase
  def setup
    @request.env["devise.mapping"] = Devise.mappings[:user]
    @user = users(:ron)
    sign_in @user
  end

  test "edit page never shows a token on plain visit" do
    @user.regenerate_api_token!

    get :edit

    assert_response :success
    assert_not_includes response.body, I18n.t("api_token.one_time_notice")
    assert_includes response.body, I18n.t("api_token.regenerate")
  end

  test "edit page offers to generate a token when none exists" do
    get :edit

    assert_response :success
    assert_includes response.body, I18n.t("api_token.status_absent")
    assert_includes response.body, I18n.t("api_token.generate")
  end
end
