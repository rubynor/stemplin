require "test_helper"

class LocaleControllerTest < ActionController::TestCase
  setup do
    @user = users(:joe)
    @request.env["HTTP_REFERER"] = "/reports"
  end

  test "signed in user switches to Norwegian and is sent back" do
    sign_in @user
    get :update, params: { locale: "nb" }

    assert_redirected_to "/reports"
    assert_equal "nb", @user.reload.locale
  end

  test "signed in user switches back to English" do
    @user.update!(locale: "nb")
    sign_in @user
    get :update, params: { locale: "en" }

    assert_redirected_to "/reports"
    assert_equal "en", @user.reload.locale
  end

  test "unknown locale is ignored" do
    sign_in @user
    get :update, params: { locale: "xx" }

    assert_redirected_to "/reports"
    assert_equal "en", @user.reload.locale
  end

  test "works for every role" do
    [ users(:organization_admin), users(:organization_user), users(:organization_spectator) ].each do |user|
      sign_in user
      get :update, params: { locale: "nb" }
      assert_response :redirect
      assert_equal "nb", user.reload.locale
    end
  end

  test "signed out visitor is sent to sign in" do
    get :update, params: { locale: "nb" }

    assert_redirected_to new_user_session_path
    assert_equal "en", @user.reload.locale
  end
end
