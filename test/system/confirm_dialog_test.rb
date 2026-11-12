require "application_system_test_case"

# Confirm messages carry names people typed in, so the dialog must show them as
# text and keep only the emphasis the messages themselves use.
class ConfirmDialogSystemTest < ApplicationSystemTestCase
  test "a name in a confirm message is shown as text, not run as HTML" do
    joe = users(:joe)
    joe.update_columns(first_name: "<img src=x onerror=\"window.confirmDialogXss=1\">", last_name: "Doe")
    sign_in_as users(:organization_admin)

    visit workspace_team_members_path
    within("##{ActionView::RecordIdentifier.dom_id(joe)}") do
      click_on I18n.t("team_members.archive")
    end

    within("#turbo-confirm-dialog") do
      assert_text "<img src="
      assert_no_selector "img"
    end
    assert_nil page.evaluate_script("window.confirmDialogXss")
  end

  test "the emphasis in a confirm message is kept" do
    sign_in_as users(:organization_admin)
    client = clients(:google_xyz)

    visit workspace_client_path(client)
    click_on I18n.t("common.delete")

    within("#turbo-confirm-dialog") do
      assert_selector "span.font-semibold", text: client.name
    end
  end
end
