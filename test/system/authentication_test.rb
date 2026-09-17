require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user signs in and lands on the time registration page" do
    user = users(:joe)

    sign_in_as user, keep_flash: true

    assert_text I18n.t("devise.sessions.signed_in")
    assert_text user.current_organization.name
  end

  test "signing in with the wrong password keeps the user out" do
    visit new_user_session_path
    fill_in "user[email]", with: users(:joe).email
    fill_in "user[password]", with: "not-the-password"
    click_button I18n.t("login_page.sign_in")

    assert_current_path new_user_session_path
    assert_text(/invalid email or password/i)
  end

  test "user signs out again" do
    user = users(:joe)
    sign_in_as user

    find("span", text: user.email).click
    click_on I18n.t("common.sign_out")

    assert_current_path new_user_session_path
  end
end
