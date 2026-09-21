require "test_helper"

# Smoke coverage: every screen in the app, visited as every role.
#
# Each role gets one class so a failure names the role and the screen. The
# assertions are deliberately coarse (renders, or redirects to the right place)
# because their job is to catch the class of bug where a screen 500s for one
# role, which per-feature tests written from the admin's point of view miss.
class ScreensByRoleTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  TURBO_STREAM = { "Accept" => "text/vnd.turbo-stream.html, text/html" }.freeze

  setup do
    @organization = organizations(:organization_one)
    @project = projects(:project_1)
    @client = clients(:e_corp)
    @member = users(:organization_user)
    @admin = users(:organization_admin)
  end

  # Screens that are the same for everyone in an organization.
  def assert_shared_screens_render
    get reports_path
    assert_response :success
    Reports::Filter::ALL_TABS.each do |tab|
      get reports_path(filter: { category: tab })
      assert_response :success, "reports #{tab} tab"
    end
    [ Reports::Filter::WEEK, Reports::Filter::YEAR ].each do |time_frame|
      get reports_path(filter: { time_frame: time_frame })
      assert_response :success, "reports #{time_frame} time frame"
    end
    get reports_path(filter: { time_frame: Reports::Filter::CUSTOM, start_date: 1.year.ago.to_date, end_date: Date.today })
    assert_response :success

    get detailed_reports_path
    assert_response :success
    get detailed_reports_path(filter: { client_ids: [ @client.id ] })
    assert_response :success
    get detailed_reports_path(filter: { project_ids: [ @project.id ] })
    assert_response :success
    get detailed_reports_path(filter: { task_ids: [ tasks(:debug).id ], user_ids: [ users(:joe).id ] })
    assert_response :success

    get edit_user_registration_path
    assert_response :success

    get privacy_policy_path
    assert_response :success

    get locale_path(locale: "nb")
    assert_response :redirect
  end

  def assert_workspace_forbidden(redirect_target)
    get workspace_projects_path
    assert_redirected_to redirect_target
    get new_workspace_project_path(client_id: @client.id)
    assert_redirected_to redirect_target
    post import_modal_workspace_projects_path, headers: TURBO_STREAM
    assert_redirected_to redirect_target
    post new_modal_workspace_clients_path, headers: TURBO_STREAM
    assert_redirected_to redirect_target
    get workspace_team_members_path
    assert_redirected_to redirect_target
    get invite_users_workspace_team_members_path
    assert_redirected_to redirect_target
    put edit_modal_workspace_team_member_path(@member), headers: TURBO_STREAM
    assert_redirected_to redirect_target
    post edit_modal_workspace_client_path(@client), headers: TURBO_STREAM
    assert_redirected_to redirect_target
    get workspace_settings_path
    assert_redirected_to redirect_target
    get edit_workspace_settings_path
    assert_redirected_to redirect_target

    # Records looked up through the workspace scopes are simply not found for
    # non-admins, which the workspace controller turns into a redirect home.
    get workspace_project_path(@project)
    assert_redirected_to root_path
    get edit_workspace_project_path(@project)
    assert_redirected_to root_path
    get workspace_client_path(@client)
    assert_redirected_to root_path
  end

  class AsAdmin < ScreensByRoleTest
    setup { sign_in @admin }

    test "time registration screens render" do
      get root_path
      assert_response :success
      get time_regs_path
      assert_response :success
      get time_regs_path(date: Date.today.prev_month.to_s)
      assert_response :success

      post new_modal_time_regs_path, headers: TURBO_STREAM
      assert_response :success
      post new_modal_time_regs_path(provide_user: true), headers: TURBO_STREAM
      assert_response :success
      post new_modal_time_regs_path(assigned_task_id: assigned_task(:task_1).id), headers: TURBO_STREAM
      assert_response :success

      # Admins may open anyone's entry in their organization.
      put edit_modal_time_reg_path(time_regs(:time_reg_1)), headers: TURBO_STREAM
      assert_response :success

      get update_tasks_select_time_regs_path(project_id: @project.id)
      assert_response :success
      get export_time_regs_path(project_id: @project.id)
      assert_response :success
    end

    test "reports, account and public screens render" do
      assert_shared_screens_render
    end

    test "workspace screens render" do
      get workspace_projects_path
      assert_response :success
      get workspace_projects_path(page: 2)
      assert_response :success
      get new_workspace_project_path(client_id: @client.id)
      assert_response :success
      get workspace_project_path(@project)
      assert_response :success
      get edit_workspace_project_path(@project)
      assert_response :success
      post import_modal_workspace_projects_path, headers: TURBO_STREAM
      assert_response :success
      post add_modal_workspace_assigned_tasks_path, headers: TURBO_STREAM
      assert_response :success

      get workspace_client_path(@client)
      assert_response :success
      post new_modal_workspace_clients_path, headers: TURBO_STREAM
      assert_response :success
      post edit_modal_workspace_client_path(@client), headers: TURBO_STREAM
      assert_response :success

      get workspace_team_members_path
      assert_response :success
      get invite_users_workspace_team_members_path
      assert_response :success
      put edit_modal_workspace_team_member_path(@member), headers: TURBO_STREAM
      assert_response :success
      put edit_modal_workspace_team_member_path(users(:organization_spectator)), headers: TURBO_STREAM
      assert_response :success

      get workspace_settings_path
      assert_response :success
      get edit_workspace_settings_path
      assert_response :success
    end

    test "the devise invitation form is disabled in favour of the team members screen" do
      # devise_invitable authenticates with force: true, which needs a session
      # cookie; the first request of a test only has the Warden test login.
      get time_regs_path

      get new_user_invitation_path
      assert_response :not_found
      post user_invitation_path, params: { user: { email: "x@example.com" } }
      assert_response :not_found
    end

    test "new project without a client redirects back with an alert" do
      get new_workspace_project_path
      assert_redirected_to workspace_projects_path
      assert_equal I18n.t("alert.client_not_found"), flash[:alert]
    end

    test "navigation shows home, workspace and reports" do
      get time_regs_path
      assert_select "nav a[href=?]", time_regs_path, text: I18n.t("common.home")
      assert_select "nav a[href=?]", workspace_projects_path, text: I18n.t("common.workspace")
      assert_select "nav a[href=?]", reports_path, text: I18n.t("common.reports")
    end

    test "detailed report shows the add-on-behalf button" do
      get detailed_reports_path
      assert_response :success
      assert_includes response.body, I18n.t("common.add_time_registration")
    end
  end

  class AsMember < ScreensByRoleTest
    setup { sign_in @member }

    test "time registration screens render" do
      get root_path
      assert_response :success
      get time_regs_path
      assert_response :success

      post new_modal_time_regs_path, headers: TURBO_STREAM
      assert_response :success
      put edit_modal_time_reg_path(time_regs(:time_reg_1_organization_user_1)), headers: TURBO_STREAM
      assert_response :success
      get update_tasks_select_time_regs_path(project_id: @project.id)
      assert_response :success
    end

    test "cannot open someone else's time registration" do
      put edit_modal_time_reg_path(time_regs(:time_reg_1)), headers: TURBO_STREAM
      assert_redirected_to root_path
    end

    test "export only contains the member's own entries" do
      assert_operator @project.time_regs.where.not(user: @member).count, :>, 0

      get export_time_regs_path(project_id: @project.id)
      assert_response :success

      rows = CSV.parse(response.body)[1..]
      assert_equal @project.time_regs.where(user: @member).count, rows.size
      assert_equal [ @member.email ], rows.map(&:last).uniq
    end

    test "reports, account and public screens render" do
      assert_shared_screens_render
    end

    test "reports only include the member's own time" do
      get reports_path
      assert_response :success
      assert_equal [ @member ], assigns(:time_regs).map(&:user).uniq

      get detailed_reports_path
      assert_response :success
      assert_equal [ @member ], assigns(:detailed_report_data).users.to_a
      assert_not_includes response.body, I18n.t("common.add_time_registration")
    end

    test "workspace screens are off limits" do
      assert_workspace_forbidden root_path

      patch workspace_settings_path, params: { organization: { currency: "NOK" } }
      assert_redirected_to root_path
      assert_equal "USD", @organization.reload.currency
    end

    test "navigation shows home and reports but not workspace" do
      get time_regs_path
      assert_select "nav a[href=?]", time_regs_path, text: I18n.t("common.home")
      assert_select "nav a[href=?]", workspace_projects_path, count: 0
      assert_select "nav a[href=?]", reports_path, text: I18n.t("common.reports")
    end
  end

  class AsSpectator < ScreensByRoleTest
    setup do
      @spectator = users(:organization_spectator)
      sign_in @spectator
    end

    test "time registration screens redirect to reports" do
      get root_path
      assert_redirected_to reports_path
      get time_regs_path
      assert_redirected_to reports_path
      post new_modal_time_regs_path, headers: TURBO_STREAM
      assert_redirected_to reports_path
      put edit_modal_time_reg_path(time_regs(:time_reg_1)), headers: TURBO_STREAM
      assert_redirected_to reports_path
      get update_tasks_select_time_regs_path(project_id: @project.id)
      assert_redirected_to reports_path
      get export_time_regs_path(project_id: @project.id)
      assert_redirected_to reports_path
    end

    test "reports, account and public screens render" do
      assert_shared_screens_render
    end

    test "reports are limited to the projects the spectator has access to" do
      get reports_path
      assert_response :success
      assert_equal [ @project ], assigns(:time_regs).map(&:project).uniq
      assert_not_empty assigns(:time_regs)

      get detailed_reports_path
      assert_response :success
      assert_equal [ @project ], assigns(:detailed_report_data).projects.to_a
      assert_not_includes response.body, I18n.t("common.add_time_registration")
    end

    test "workspace screens are off limits" do
      assert_workspace_forbidden reports_path

      patch workspace_settings_path, params: { organization: { currency: "NOK" } }
      assert_redirected_to reports_path
      assert_equal "USD", @organization.reload.currency
    end

    test "navigation shows reports only" do
      get reports_path
      assert_select "nav a[href=?]", time_regs_path, count: 0
      assert_select "nav a[href=?]", workspace_projects_path, count: 0
      assert_select "nav a[href=?]", reports_path, text: I18n.t("common.reports")
    end
  end

  class WithoutOrganization < ScreensByRoleTest
    setup { sign_in users(:one) }

    test "every screen sends the user to the onboarding wizard" do
      [ root_path, time_regs_path, reports_path, detailed_reports_path, workspace_projects_path,
        workspace_team_members_path, workspace_settings_path, edit_user_registration_path ].each do |path|
        get path
        assert_redirected_to onboarding_wizard_path(:organization), "expected #{path} to redirect to onboarding"
      end
    end

    test "the privacy policy can be read before onboarding" do
      get privacy_policy_path
      assert_response :success
    end

    test "onboarding steps beyond the first go back to the organization step" do
      get onboarding_wizard_path(:organization)
      assert_response :success
      %i[setup_choice client project tasks].each do |step|
        get onboarding_wizard_path(step)
        assert_redirected_to onboarding_wizard_path(:organization)
      end
    end
  end

  class SignedOut < ScreensByRoleTest
    test "public screens render" do
      get root_path
      assert_redirected_to new_user_session_path
      get new_user_session_path
      assert_response :success
      get new_user_registration_path
      assert_response :success
      get new_user_password_path
      assert_response :success
      get privacy_policy_path
      assert_response :success
      get "/manifest.json"
      assert_response :success
      get "/service_worker.js"
      assert_response :success
      get "/robots.txt"
      assert_response :success
    end

    test "invitation form requires sign in" do
      get new_user_invitation_path
      assert_redirected_to new_user_session_path
    end

    test "authenticated screens redirect to sign in" do
      [ time_regs_path, reports_path, detailed_reports_path, edit_user_registration_path,
        onboarding_wizard_path(:organization), workspace_projects_path, workspace_project_path(@project),
        workspace_client_path(@client), workspace_team_members_path, invite_users_workspace_team_members_path,
        workspace_settings_path, edit_workspace_settings_path, export_time_regs_path(project_id: @project.id),
        update_tasks_select_time_regs_path(project_id: @project.id), locale_path(locale: "nb") ].each do |path|
        get path
        assert_redirected_to new_user_session_path, "expected #{path} to require sign in"
      end

      post new_modal_time_regs_path, headers: TURBO_STREAM
      assert_redirected_to new_user_session_path
      post new_modal_workspace_clients_path, headers: TURBO_STREAM
      assert_redirected_to new_user_session_path
      post add_modal_workspace_assigned_tasks_path, headers: TURBO_STREAM
      assert_redirected_to new_user_session_path
      post set_current_organization_path(@organization)
      assert_redirected_to new_user_session_path
      post time_reg_copies_path(time_regs(:time_reg_1))
      assert_redirected_to new_user_session_path
    end
  end
end
