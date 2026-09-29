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
        password_reset: { en: { template_id: "password_reset_template_id" } }
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

  test "project share invitation is a plain Rails email naming the client and the sharing organization" do
    project = projects(:project_1)
    share = ProjectShare.create!(project: project, invited_email: "newcomer@example.com", invited_by: users(:organization_admin))

    email = UserMailer.project_share_invitation_email(project_shares: [ share ])
    assert_emails(1) { email.deliver_now }

    assert_equal [ "newcomer@example.com" ], email.to
    assert_equal "#{project.organization.name} has shared #{project.name} (#{project.client.name}) with you", email.subject
    [ email.html_part, email.text_part ].each do |part|
      assert_includes part.body.to_s, "/share_invitations/#{share.invitation_token}"
      assert_includes part.body.to_s, users(:organization_admin).name
      assert_includes part.body.to_s, project.organization.name
      assert_includes part.body.to_s, project.client.name
    end
  end

  test "several projects shared together go out as one email listing them all" do
    projects = [ projects(:project_1), projects(:project_2) ]
    shares = projects.map { |project| ProjectShare.create!(project: project, invited_email: "newcomer@example.com", invited_by: users(:organization_admin)) }

    email = UserMailer.project_share_invitation_email(project_shares: shares)

    assert_equal "#{projects.first.organization.name} has shared 2 projects for #{projects.first.client.name} with you", email.subject
    [ email.html_part, email.text_part ].each do |part|
      projects.each { |project| assert_includes part.body.to_s, project.name }
      assert_includes part.body.to_s, "/share_invitations/#{shares.first.invitation_token}"
    end
  end

  test "project share invitation uses the invited user's locale" do
    users(:customer_admin).update!(locale: "nb")
    share = ProjectShare.create!(project: projects(:project_1), invited_email: users(:customer_admin).email, invited_by: users(:organization_admin))

    email = UserMailer.project_share_invitation_email(project_shares: [ share ])

    assert_match(/har delt/, email.subject)
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
