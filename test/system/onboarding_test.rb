require "application_system_test_case"

class OnboardingTest < ApplicationSystemTestCase
  test "a user without an organization is taken through the first wizard step" do
    user = users(:one)
    assert_empty user.organizations, "fixture user is expected to start without an organization"

    # A user without an organization is redirected into the wizard on sign-in.
    # Letting the app navigate, rather than visiting the step directly, keeps a
    # late redirect from wiping what has been typed into the form.
    sign_in_as user
    assert_current_path onboarding_wizard_path(:organization)
    assert_text I18n.t("common.onboarding.organization.title")

    assert_difference -> { Organization.count }, 1 do
      fill_in "organization[name]", with: "Nordlys Consulting"
      select_currency "NOK"
      assert_field "organization[name]", with: "Nordlys Consulting"
      click_on I18n.t("common.onboarding.organization.create")

      assert_current_path onboarding_wizard_path(:setup_choice)
    end

    assert_equal "Nordlys Consulting", user.reload.current_organization.name
  end

  private

  def select_currency(code)
    option = find("#organization_currency option[value='#{code}']").text
    select option, from: "organization_currency"
  end
end
