require "test_helper"

class PrivacyPolicyControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "renders the policy with every section in English" do
    get privacy_policy_path
    assert_response :success
    assert_select "h1", I18n.t("privacy_policy.title")
    I18n.t("privacy_policy.sections").each do |section|
      assert_select "h2", section[:title]
    end
  end

  test "renders the policy in Norwegian" do
    get privacy_policy_path(locale: "nb")
    assert_response :success
    assert_select "h1", I18n.t("privacy_policy.title", locale: :nb)
  end

  test "names every third party that processes personal data" do
    get privacy_policy_path
    %w[Hetzner SendGrid Clarity PostHog Sentry].each do |processor|
      assert_includes response.body, processor, "#{processor} is used by the app and must be listed"
    end
  end

  test "is linked from the sign in page" do
    get new_user_session_path
    assert_select "a[href=?]", privacy_policy_path
  end

  test "is linked from the app footer for signed in users" do
    sign_in users(:organization_spectator)
    get reports_path
    assert_select "footer a[href=?]", privacy_policy_path
  end
end
