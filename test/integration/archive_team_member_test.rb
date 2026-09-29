require "test_helper"

class ArchiveTeamMemberTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @organization = organizations(:organization_one)
    @admin = users(:organization_admin)
    @joe = users(:joe) # member of organization_one only
    @ron = users(:ron) # member of organization_one and organization_two
  end

  def archive(user)
    patch archive_workspace_team_member_path(user)
  end

  test "an admin archives a member, who moves from the active to the archived list" do
    sign_in @admin
    archive @joe
    assert_redirected_to workspace_team_members_path

    assert access_infos(:access_info_1).reload.archived?

    get workspace_team_members_path
    assert_select "tr##{dom_id(@joe)}", count: 0

    get workspace_team_members_path(archived: 1)
    assert_select "tr##{dom_id(@joe)}"
  end

  test "restoring brings the member back with their role and project access" do
    access_info = access_infos(:access_info_org1_user)
    project_ids = access_info.projects.ids
    assert project_ids.any?

    sign_in @admin
    archive users(:organization_user)
    patch restore_workspace_team_member_path(users(:organization_user))
    assert_redirected_to workspace_team_members_path(archived: 1)

    access_info.reload
    assert_not access_info.archived?
    assert_equal "organization_user", access_info.role
    assert_equal project_ids.sort, access_info.projects.ids.sort
  end

  test "admins can't archive themselves or the last admin" do
    sign_in @admin
    archive @admin
    assert_not access_infos(:access_info_org1_admin).reload.archived?

    assert_not access_infos(:access_info_org1_admin).archive
    assert_includes access_infos(:access_info_org1_admin).errors.full_messages.to_sentence, I18n.t("activerecord.errors.models.access_info.attributes.organization.must_have_at_least_one_admin")
  end

  test "non-admins can't archive anyone" do
    sign_in users(:organization_user)
    archive @joe
    assert_not access_infos(:access_info_1).reload.archived?
  end

  test "someone archived in their only organization is signed out and can't sign back in" do
    sign_in @joe
    access_infos(:access_info_1).archive

    get time_regs_path
    assert_redirected_to new_user_session_path

    post user_session_path, params: { user: { email: @joe.email, password: "password" } }
    assert_equal I18n.t("devise.failure.archived"), flash[:alert]
  end

  test "someone archived in one of several organizations keeps using the others" do
    access_infos(:access_info_3).update!(active: true)
    access_infos(:access_info_2).update!(active: false)
    access_infos(:access_info_3).archive

    assert @ron.reload.active_for_authentication?
    assert_equal organizations(:organization_two), @ron.current_organization
    assert_not_includes @ron.organizations, @organization

    sign_in @ron
    post set_current_organization_path(@organization)
    assert_equal organizations(:organization_two), @ron.reload.current_organization
  end

  test "archived members drop out of pickers but stay in reports" do
    access_infos(:access_info_1).archive
    sign_in @admin

    post new_modal_time_regs_path(provide_user: "true"), as: :turbo_stream
    assert_response :success
    assert_select "select[name='time_reg[user_id]'] option", text: @ron.name
    assert_select "select[name='time_reg[user_id]'] option", text: @joe.name, count: 0

    get reports_path(filter: { time_frame: "custom", start_date: 1.month.ago.to_date, end_date: Date.current, category: Reports::Filter::USERS })
    assert_response :success
    assert_includes response.body, @joe.name
  end

  test "re-inviting an archived member restores them" do
    access_infos(:access_info_1).archive
    sign_in @admin

    assert_no_difference("AccessInfo.count") do
      post workspace_team_members_path, params: { invite_users_hash: { "0" => { email: @joe.email, role: "organization_admin", project_ids: [] } } }
    end
    assert_redirected_to workspace_team_members_path

    access_info = access_infos(:access_info_1).reload
    assert_not access_info.archived?
    assert_equal "organization_admin", access_info.role
  end

  test "archived members can't be booked on the plan but existing bookings stay visible and editable" do
    monday = Date.new(2026, 9, 21)
    booking = @organization.plan_assignments.create!(project: projects(:project_1), user: @joe, start_date: monday, end_date: monday + 4, minutes_per_day: 240)
    access_infos(:access_info_1).archive

    assert booking.update(end_date: monday + 2)
    assert_not @organization.plan_assignments.new(project: projects(:project_1), user: @joe, start_date: monday, end_date: monday, minutes_per_day: 60).valid?

    sign_in @admin
    get plan_data_path, params: { start: monday.iso8601, end: (monday + 6).iso8601 }, headers: { "Accept" => "application/json" }
    assert_includes response.parsed_body["people"].map { |p| p["id"] }, @joe.id

    get plan_data_path, params: { start: (monday + 30).iso8601, end: (monday + 36).iso8601 }, headers: { "Accept" => "application/json" }
    assert_not_includes response.parsed_body["people"].map { |p| p["id"] }, @joe.id
  end
end
