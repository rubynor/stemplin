require "application_system_test_case"

class ClientSharingTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper

  test "an admin shares several of a client's projects from the clients and projects list" do
    client = clients(:e_corp)
    sign_in_as users(:organization_admin)
    visit workspace_projects_path
    shot "list_before"

    within("##{ActionView::RecordIdentifier.dom_id(client)}") { click_on I18n.t("project_shares.client.button") }
    assert_text I18n.t("project_shares.client.title", client: client.name)
    uncheck projects(:to_be_deleted).name
    fill_in I18n.t("activerecord.attributes.project_share.invited_email"), with: users(:customer_admin).email
    shot "modal"

    assert_enqueued_emails 1 do
      click_on I18n.t("project_shares.invite_button")
      assert_text I18n.t("project_shares.notice.invited_many", count: 2, email: users(:customer_admin).email)
    end
    assert_no_text I18n.t("project_shares.client.title", client: client.name)
    assert_selector "##{ActionView::RecordIdentifier.dom_id(client)}", text: I18n.t("project_shares.list.pending"), count: 1
    assert_equal [ projects(:project_1), projects(:project_2) ].sort_by(&:id), ProjectShare.pending.map(&:project).sort_by(&:id)
    shot "list_after"
  end

  private

  def shot(name)
    page.save_screenshot(File.join(ENV["SHOTS"], "#{name}.png")) if ENV["SHOTS"]
  end
end
