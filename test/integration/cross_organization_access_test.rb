require "test_helper"

# An admin of one organization must not be able to read or change anything in
# another organization, even one they are also a member of but have not
# switched to. organization_admin is an admin in both organizations; here they
# are active in organization_two and poke at organization_one's records.
class CrossOrganizationAccessTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  TURBO_STREAM = { "Accept" => "text/vnd.turbo-stream.html, text/html" }.freeze

  setup do
    @admin = users(:organization_admin)
    access_infos(:access_info_org1_admin).update!(active: false)
    access_infos(:access_info_org2_admin).update!(active: true)
    assert_equal organizations(:organization_two), @admin.current_organization

    @project = projects(:project_1)
    @client = clients(:e_corp)
    @colleague = users(:joe)
    @time_reg = time_regs(:time_reg_1)
    sign_in @admin
  end

  test "workspace projects of the other organization are not found" do
    get workspace_project_path(@project)
    assert_redirected_to root_path
    get edit_workspace_project_path(@project)
    assert_redirected_to root_path

    patch workspace_project_path(@project), params: { project: { name: "Hijacked" } }
    assert_redirected_to root_path
    assert_not_equal "Hijacked", @project.reload.name

    delete workspace_project_path(@project)
    assert_redirected_to root_path
    assert @project.reload.kept?
  end

  test "clients of the other organization cannot be shown or changed" do
    get workspace_client_path(@client)
    assert_redirected_to root_path

    post edit_modal_workspace_client_path(@client), headers: TURBO_STREAM
    assert_redirected_to root_path

    patch workspace_client_path(@client), params: { client: { name: "Hijacked" } }, headers: TURBO_STREAM
    assert_redirected_to root_path
    assert_not_equal "Hijacked", @client.reload.name

    delete workspace_client_path(@client), headers: TURBO_STREAM
    assert_redirected_to root_path
    assert @client.reload.kept?
  end

  test "team members of the other organization cannot be edited" do
    put edit_modal_workspace_team_member_path(@colleague), headers: TURBO_STREAM
    assert_redirected_to root_path

    assert_no_difference -> { AccessInfo.count } do
      patch workspace_team_member_path(@colleague), params: { user: { role: :organization_admin, project_ids: [] } }, headers: TURBO_STREAM
    end
    assert_redirected_to root_path
    assert_equal "organization_user", @colleague.access_info(organizations(:organization_one)).role
  end

  test "time registrations of the other organization cannot be opened, changed, copied or deleted" do
    put edit_modal_time_reg_path(@time_reg), headers: TURBO_STREAM
    assert_redirected_to root_path

    patch time_reg_path(@time_reg), params: { time_reg: { notes: "Hijacked" } }
    assert_redirected_to root_path
    assert_not_equal "Hijacked", @time_reg.reload.notes

    patch time_reg_toggle_active_path(@time_reg)
    assert_redirected_to root_path
    assert_not @time_reg.reload.active?

    assert_no_difference -> { TimeReg.count } do
      post time_reg_copies_path(@time_reg), params: { date: Date.today.to_s }
    end
    assert_redirected_to root_path

    delete time_reg_path(@time_reg)
    assert_redirected_to root_path
    assert TimeReg.exists?(@time_reg.id)
  end

  test "time cannot be registered on the other organization's tasks" do
    assert_no_difference -> { TimeReg.count } do
      post time_regs_path, params: { time_reg: { date_worked: Date.today, minutes: 30, assigned_task_id: assigned_task(:task_1).id } }
    end
    assert_redirected_to root_path
  end

  test "the other organization's project cannot be exported" do
    get export_time_regs_path(project_id: @project.id)
    assert_response :not_found
  end

  test "report filters pointing at the other organization return no data" do
    get reports_path(filter: { client_ids: [ @client.id ], project_ids: [ @project.id ], user_ids: [ @colleague.id ] })
    assert_response :success
    assert_empty assigns(:time_regs)

    get detailed_reports_path(filter: { client_ids: [ @client.id ] })
    assert_response :success
    assert_empty assigns(:time_regs)
    assert_not_includes response.body, @time_reg.notes
  end

  test "switching to an organization the admin is not part of is refused" do
    other = organizations(:one)
    post set_current_organization_path(other)
    assert_redirected_to root_path
    assert_equal organizations(:organization_two), @admin.reload.current_organization
  end
end
