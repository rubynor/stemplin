require "application_system_test_case"

class ArchiveTeamMemberSystemTest < ApplicationSystemTestCase
  test "admin archives a member who has left and restores them again" do
    joe = users(:joe)
    sign_in_as users(:organization_admin)

    visit workspace_team_members_path
    within("##{ActionView::RecordIdentifier.dom_id(joe)}") do
      click_on I18n.t("team_members.archive")
    end
    within("#turbo-confirm-dialog") { click_on "Accept" }

    assert_text I18n.t("notice.member_archived", name: joe.name)
    assert_no_selector "##{ActionView::RecordIdentifier.dom_id(joe)}"

    click_on I18n.t("team_members.archived")
    assert_button I18n.t("team_members.restore")
    within("##{ActionView::RecordIdentifier.dom_id(joe)}") do
      click_on I18n.t("team_members.restore")
    end

    assert_text I18n.t("notice.member_restored", name: joe.name)
    assert_not access_infos(:access_info_1).reload.archived?
  end
end
