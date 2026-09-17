require "application_system_test_case"

class OnboardingTest < ApplicationSystemTestCase
  test "a user without an organization is taken through the first wizard step" do
    user = users(:one)
    assert_empty user.organizations, "fixture user is expected to start without an organization"

    sign_in_as user
    visit onboarding_wizard_path(:organization)

    assert_text I18n.t("common.onboarding.organization.title")

    assert_difference -> { Organization.count }, 1 do
      fill_in "organization[name]", with: "Nordlys Consulting"
      select_currency "NOK"
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
