require "application_system_test_case"

class OrganizationSwitchingTest < ApplicationSystemTestCase
  test "user switches to another organization from the header dialog" do
    admin = users(:organization_admin)
    current = organizations(:organization_one)
    other = organizations(:organization_two)
    assert_equal current, admin.current_organization

    sign_in_as admin

    find("span", text: current.name).click
    assert_text I18n.t("common.organizations")
    click_on other.name

    # The switch is a full page reload (turbo is disabled on that button), so
    # wait for the dialog to be gone before checking what was persisted.
    assert_no_text I18n.t("common.organizations")
    assert_selector "span", text: other.name
    assert_equal other, admin.reload.current_organization
  end
end
