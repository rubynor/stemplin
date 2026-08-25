require "test_helper"

class Users::ApiTokensControllerTest < ActionController::TestCase
  def setup
    @user = users(:ron)
  end

  test "unauthenticated create redirects to sign in" do
    post :create

    assert_redirected_to new_user_session_path
    assert_nil @user.reload.api_token_digest
  end

  test "create changes digest and shows token exactly once with warning" do
    sign_in @user

    post :create

    assert_response :unprocessable_entity
    token = assigns(:api_token)
    assert token.present?
    assert_equal 1, response.body.scan(token).count
    assert_includes response.body, I18n.t("api_token.one_time_notice")
    assert_equal Digest::SHA256.hexdigest(token), @user.reload.api_token_digest
  end

  test "regenerating invalidates previous token" do
    old_token = @user.regenerate_api_token!
    sign_in @user

    post :create

    assert_nil User.find_by_api_token(old_token)
    assert_equal @user, User.find_by_api_token(assigns(:api_token))
  end
end
