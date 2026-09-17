require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  # ApplicationMailer only talks to SendGrid in production and staging; anywhere
  # else `mail` returns early. This subclass captures the headers the mailer
  # action builds, which is the part worth asserting on.
  class CapturingUserMailer < UserMailer
    class << self
      attr_accessor :captured_headers
    end

    def mail(headers = nil, &block)
      self.class.captured_headers = headers
      true
    end
  end

  setup do
    @user = users(:joe)
    @organization_name = @user.current_organization.name
    @url = "http://test.stemplin.com"

    @original_templates = Stemplin.config.emails.templates
    Stemplin.config.emails.templates = {
      user: {
        welcome: { en: { template_id: "welcome_template_id" } },
        password_reset: { en: { template_id: "password_reset_template_id" } },
        project_invitation: { en: { template_id: "project_invitation_template_id" } }
      }
    }
    I18n.locale = :en
    CapturingUserMailer.captured_headers = nil
  end

  teardown do
    Stemplin.config.emails.templates = @original_templates
    I18n.locale = I18n.default_locale
  end

  test "welcome email uses the locale's template and carries the user's details" do
    headers = capture_headers do
      CapturingUserMailer.welcome_email(user: @user, organization_name: @organization_name, url: @url)
    end

    assert_equal @user.email, headers[:to]
    assert_equal "welcome_template_id", headers[:sendgrid_template]
    assert_equal @organization_name, headers[:content][:organization_name]
    assert_equal @user.name, headers[:content][:user_name]
    assert_equal @url, headers[:content][:url]
  end

  test "password reset email carries a link containing the reset token" do
    token = "reset_token_123"

    headers = capture_headers do
      CapturingUserMailer.reset_password_instructions(@user, token)
    end

    assert_equal @user.email, headers[:to]
    assert_equal "password_reset_template_id", headers[:sendgrid_template]
    assert_equal @user.name, headers[:content][:user_name]
    assert_includes headers[:content][:url], "reset_password_token=#{token}"
  end

  test "project invitation email is addressed to the invited email" do
    project = projects(:project_1)
    inviting_user = users(:organization_admin)
    invitation = ProjectInvitation.new(invited_email: "newcomer@example.com", project: project, invited_by: inviting_user)

    headers = capture_headers do
      CapturingUserMailer.project_invitation_email(project_invitation: invitation, inviting_user: inviting_user, project: project)
    end

    assert_equal "newcomer@example.com", headers[:to]
    assert_equal "project_invitation_template_id", headers[:sendgrid_template]
    assert_equal project.name, headers[:content][:project_name]
    assert_equal project.client.name, headers[:content][:client_name]
    assert_equal inviting_user.name, headers[:content][:inviting_user_name]
  end

  test "headers are turned into a SendGrid payload with a personalization" do
    headers = {
      to: @user.email,
      sendgrid_template: "welcome_template_id",
      content: { user_name: @user.name, url: @url }
    }

    # SendGrid::Mail#to_json returns a hash rather than a JSON string.
    payload = UserMailer.new.send(:build_mail, headers).to_json
    personalization = payload["personalizations"].first

    assert_equal "welcome_template_id", payload["template_id"]
    assert_equal Stemplin.config.emails.from, payload["from"]["email"]
    assert_equal @user.email, personalization["to"].first["email"]
    # The content hash is merged as-is, so its keys stay symbols.
    assert_equal @user.name, personalization["dynamic_template_data"][:user_name]
    assert_equal @url, personalization["dynamic_template_data"][:url]
  end

  test "no mail is handed to SendGrid outside production and staging" do
    headers = { to: @user.email, sendgrid_template: "welcome_template_id" }

    # A SendGrid call would need an API key and network access; the guard
    # returning true is what keeps development and test from sending real mail.
    assert_equal true, UserMailer.new.send(:handle_sendgrid_template, headers)
  end

  private

  def capture_headers
    yield.deliver_now
    headers = CapturingUserMailer.captured_headers
    assert_not_nil headers, "expected the mailer action to build headers"
    headers
  end
end
