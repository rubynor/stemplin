require "test_helper"

class PlanTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  JSON_HEADERS = { "Accept" => "application/json" }.freeze

  setup do
    @organization = organizations(:organization_one)
    @admin = users(:organization_admin)
    @member = users(:organization_user) # has access to project_1 only
    @project = projects(:project_1)
    @hidden_project = projects(:project_2)
    @monday = Date.new(2026, 9, 21)
    @range = { start: @monday.iso8601, end: (@monday + 27).iso8601 }

    @visible = @organization.plan_assignments.create!(project: @project, user: users(:joe), start_date: @monday, end_date: @monday + 4, minutes_per_day: 240)
    @hidden = @organization.plan_assignments.create!(project: @hidden_project, user: users(:joe), start_date: @monday, end_date: @monday + 4, minutes_per_day: 120)
    @own_time_off = @organization.plan_assignments.create!(project: nil, user: @member, start_date: @monday + 7, end_date: @monday + 8, minutes_per_day: 450)
    @milestone = @organization.plan_milestones.create!(project: @project, name: "Launch", date: @monday + 10)
  end

  def data
    get plan_data_path, params: @range, headers: JSON_HEADERS
    assert_response :success
    response.parsed_body
  end

  def create_params(**overrides)
    { assignment: { project_id: @project.id, user_id: users(:joe).id, start_date: @monday.iso8601, end_date: (@monday + 4).iso8601, minutes_per_day: 300 }.merge(overrides) }
  end

  test "the plan page mounts the frontend for every role" do
    [ @admin, @member, users(:organization_spectator) ].each do |user|
      sign_in user
      get plan_schedule_path(view: "team")
      assert_response :success
      assert_select "#plan-app[data-controller='plan-app']"
      sign_out user
    end
  end

  test "admins get the whole organization and may edit" do
    sign_in @admin
    body = data

    assert body["canEdit"]
    assert_equal [ @visible.id, @hidden.id, @own_time_off.id ].sort, body["assignments"].map { |a| a["id"] }.sort
    assert_includes body["people"].map { |p| p["id"] }, @member.id
    assert_equal [ "Launch" ], body["milestones"].map { |m| m["name"] }
    assert_not_includes body["projects"].map { |p| p["id"] }, projects(:org_two_project).id
  end

  test "members only see assignments on their projects plus their own" do
    sign_in @member
    body = data

    assert_not body["canEdit"]
    assert_equal [ @visible.id, @own_time_off.id ].sort, body["assignments"].map { |a| a["id"] }.sort
    assert_equal [ @project.id ], body["projects"].map { |p| p["id"] }
    assert_equal [ users(:joe).id, @member.id ].sort, body["people"].map { |p| p["id"] }.sort
  end

  test "people see the projects they are booked on, even without access to them" do
    @organization.plan_assignments.create!(project: @hidden_project, user: @member, start_date: @monday, end_date: @monday, minutes_per_day: 60)
    sign_in @member

    assert_equal [ @project.id, @hidden_project.id ].sort, data["projects"].map { |p| p["id"] }.sort
  end

  test "tracked time is summed per person, project and week" do
    sign_in @admin
    TimeReg.where(user: users(:joe)).delete_all
    assigned_task = @project.assigned_tasks.first
    [ 60, 60, 90 ].each { |minutes| TimeReg.create!(user: users(:joe), assigned_task: assigned_task, date_worked: @monday + 1, minutes: minutes) }

    actual = data["actuals"].find { |row| row["userId"] == users(:joe).id }

    assert_equal({ "userId" => users(:joe).id, "projectId" => @project.id, "week" => @monday.iso8601, "minutes" => 210 }, actual)
  end

  test "an invalid range is rejected" do
    sign_in @admin
    get plan_data_path, params: { start: "2026-01-10", end: "2026-01-01" }, headers: JSON_HEADERS
    assert_response :bad_request
  end

  test "admins create assignments, repeated weekly" do
    sign_in @admin

    assert_difference -> { Plan::Assignment.count }, 3 do
      post plan_assignments_path, params: create_params(repeat_weeks: 3), headers: JSON_HEADERS, as: :json
    end
    assert_response :created
    assert_equal [ @monday, @monday + 7, @monday + 14 ].map(&:iso8601), response.parsed_body.map { |a| a["startDate"] }
  end

  test "time off and placeholders can be scheduled" do
    sign_in @admin
    placeholder = @organization.plan_placeholders.create!(name: "Designer")

    post plan_assignments_path, params: create_params(project_id: nil), headers: JSON_HEADERS, as: :json
    assert_response :created
    assert_nil response.parsed_body.first["projectId"]

    post plan_assignments_path, params: create_params(user_id: nil, placeholder_id: placeholder.id), headers: JSON_HEADERS, as: :json
    assert_response :created
    assert_equal placeholder.id, response.parsed_body.first["placeholderId"]
  end

  test "invalid assignments come back with messages" do
    sign_in @admin
    post plan_assignments_path, params: create_params(end_date: (@monday - 1).iso8601), headers: JSON_HEADERS, as: :json

    assert_response :unprocessable_entity
    assert_match "start date", response.parsed_body["errors"].join
  end

  test "admins move, split and delete assignments" do
    sign_in @admin

    patch plan_assignment_path(@visible), params: { assignment: { start_date: (@monday + 7).iso8601, end_date: (@monday + 11).iso8601 } }, headers: JSON_HEADERS, as: :json
    assert_response :success
    assert_equal @monday + 7, @visible.reload.start_date

    post split_plan_assignment_path(@visible), params: { date: (@monday + 9).iso8601 }, headers: JSON_HEADERS, as: :json
    assert_response :success
    assert_equal 2, response.parsed_body.size
    assert_equal @monday + 8, @visible.reload.end_date

    delete plan_assignment_path(@visible), headers: JSON_HEADERS
    assert_response :no_content
    assert_not Plan::Assignment.exists?(@visible.id)
  end

  test "members and spectators cannot change the plan" do
    [ @member, users(:organization_spectator) ].each do |user|
      sign_in user

      assert_no_difference -> { Plan::Assignment.count } do
        post plan_assignments_path, params: create_params, headers: JSON_HEADERS, as: :json
      end
      assert_response :forbidden

      patch plan_assignment_path(@visible), params: { assignment: { minutes_per_day: 60 } }, headers: JSON_HEADERS, as: :json
      assert_response :forbidden
      assert_equal 240, @visible.reload.minutes_per_day

      sign_out user
    end
  end

  test "records from another organization cannot be used or reached" do
    sign_in @admin

    post plan_assignments_path, params: create_params(project_id: projects(:org_two_project).id), headers: JSON_HEADERS, as: :json
    assert_response :not_found

    post plan_assignments_path, params: create_params(user_id: users(:org_admin_without_org).id), headers: JSON_HEADERS, as: :json
    assert_response :not_found

    # Switched to organization two, organization one's plan is out of reach.
    access_infos(:access_info_org1_admin).update!(active: false)
    access_infos(:access_info_org2_admin).update!(active: true)
    patch plan_assignment_path(@visible), params: { assignment: { minutes_per_day: 60 } }, headers: JSON_HEADERS, as: :json
    assert_response :not_found
    delete plan_milestone_path(@milestone), headers: JSON_HEADERS
    assert_response :not_found
    assert_equal 240, @visible.reload.minutes_per_day
  end

  test "milestones and placeholders are managed by admins" do
    sign_in @admin

    post plan_milestones_path, params: { milestone: { project_id: @project.id, name: "Beta", date: @monday.iso8601 } }, headers: JSON_HEADERS, as: :json
    assert_response :created

    post plan_placeholders_path, params: { placeholder: { name: "Designer", roles: "UX" } }, headers: JSON_HEADERS, as: :json
    assert_response :created
    placeholder = Plan::Placeholder.find(response.parsed_body["id"])

    patch plan_placeholder_path(placeholder), params: { placeholder: { name: "Senior designer" } }, headers: JSON_HEADERS, as: :json
    assert_equal "Senior designer", placeholder.reload.name

    delete plan_placeholder_path(placeholder), headers: JSON_HEADERS
    assert_response :no_content
  end

  test "admins set capacity, colour and shift a project's timeline" do
    sign_in @admin

    patch plan_person_path(users(:joe)), params: { person: { plan_weekly_capacity_minutes: 1800, plan_work_days: 0b0001111 } }, headers: JSON_HEADERS, as: :json
    assert_response :success
    assert_equal 1800, access_infos(:access_info_1).reload.plan_capacity_minutes

    patch plan_project_path(@project), params: { project: { color: "magenta" } }, headers: JSON_HEADERS, as: :json
    assert_response :success
    assert_equal "magenta", @project.reload.plan_color

    patch plan_project_path(@project), params: { project: { color: "chartreuse" } }, headers: JSON_HEADERS, as: :json
    assert_response :unprocessable_entity

    post shift_plan_project_path(@project), params: { from: @monday.iso8601, to: (@monday + 14).iso8601 }, headers: JSON_HEADERS, as: :json
    assert_response :no_content
    assert_equal @monday + 14, @visible.reload.start_date
    assert_equal @monday + 24, @milestone.reload.date
    assert_equal @monday, @hidden.reload.start_date, "other projects stay put"
  end

  test "the export is a CSV of planned hours per week" do
    sign_in @admin
    get plan_export_path, params: { view: "team", period: "weekly", start: @monday.iso8601, end: (@monday + 13).iso8601 }

    assert_response :success
    rows = CSV.parse(response.body)
    assert_equal [ "Person", "Client", "Project", @monday.iso8601, (@monday + 7).iso8601, "Total" ], rows.first
    assert_includes rows, [ users(:joe).name, "E Corp", @project.name, "20.0", "0.0", "20.0" ]
  end

  test "members only export what they can see" do
    sign_in @member
    get plan_export_path, params: { view: "projects", period: "monthly", start: @monday.iso8601, end: (@monday + 13).iso8601 }

    assert_response :success
    assert_no_match @hidden_project.name, response.body
  end

  test "a split date outside the assignment is refused" do
    sign_in @admin
    post split_plan_assignment_path(@visible), params: { date: @monday.iso8601 }, headers: JSON_HEADERS, as: :json

    assert_response :unprocessable_entity
    assert_equal [ I18n.t("plan.errors.split_date") ], response.parsed_body["errors"]
  end

  test "dates that do not parse are rejected" do
    sign_in @admin
    get plan_data_path, params: { start: "next tuesday", end: "2026-01-01" }, headers: JSON_HEADERS

    assert_response :bad_request
  end

  test "an export needs a valid range" do
    sign_in @admin
    get plan_export_path, params: { start: "2026-01-10", end: "2026-01-01" }

    assert_response :bad_request
  end

  test "an HTML request that is not allowed goes back to the start page" do
    sign_in @member
    delete plan_assignment_path(@visible)

    assert_redirected_to root_path
    assert Plan::Assignment.exists?(@visible.id)
  end

  test "spectators are left off the plan and can't be booked" do
    spectator = users(:organization_spectator)
    sign_in @admin

    assert_not_includes data["people"].map { |p| p["id"] }, spectator.id

    post plan_assignments_path, params: create_params(user_id: spectator.id), headers: JSON_HEADERS
    assert_response :unprocessable_entity
  end

  test "someone made a spectator stays on the plan while they have bookings" do
    @organization.plan_assignments.create!(project: @project, user: @member, start_date: @monday, end_date: @monday + 4, minutes_per_day: 240)
    access_infos(:access_info_org1_user).update!(role: :organization_spectator)
    sign_in @admin

    assert_includes data["people"].map { |p| p["id"] }, @member.id
  end
end
