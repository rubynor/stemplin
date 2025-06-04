require "test_helper"

class PasswordResetIntegrationTest < ActionDispatch::IntegrationTest
  test "should start reset password process when requested" do
    user = users(:joe)
    assert_nil user.reset_password_token
    assert_nil user.reset_password_sent_at

    post user_password_path, params: {
      user: { email: user.email }
    }

    user.reload
    assert_not_nil user.reset_password_token
    assert_not_nil user.reset_password_sent_at
    assert_in_delta Time.current, user.reset_password_sent_at, 1.minute
  end

  test "should not start reset password process when requested by a bot" do
    user = users(:joe)
    assert_nil user.reset_password_token
    assert_nil user.reset_password_sent_at

    post user_password_path, params: {
      user: {
        email: user.email,
        honeypot_field: "bot data"
      }
    }

    user.reload
    assert_nil user.reset_password_token
    assert_nil user.reset_password_sent_at
  end
end
