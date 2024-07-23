require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:joe)
    @organization_name = @user.current_organization
    @url = "http://test.stemplin.com"
    @token = "reset_token_123"

    # Mocking config
    Stemplin.config.emails.templates = {
      user: {
        welcome: {
          en: { template_id: "welcome_template_id" }
        },
        password_reset: {
          en: { template_id: "password_reset_template_id" }
        }
      }
    }
    I18n.locale = :en
  end

  test "welcome_email" do
    email = UserMailer.welcome_email(user: @user, organization_name: @organization_name, url: @url)
    content = email.header["content"].unparsed_value

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @user.email ], email.to
    assert_equal email.header["sendgrid_template"].unparsed_value, "welcome_template_id"
    assert_equal @organization_name, content[:organization_name]
    assert_equal @user.name, content[:user_name]
    assert_equal @url, content[:url]
  end

  test "reset_password_instructions" do
    email = UserMailer.reset_password_instructions(@user, @token)
    content = email.header["content"].unparsed_value

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ @user.email ], email.to
    assert_equal email.header["sendgrid_template"].unparsed_value, "password_reset_template_id"
    assert_equal @user.name, content[:user_name]
    assert_match /reset_password_token=#{@token}/, content[:url]
  end
end
