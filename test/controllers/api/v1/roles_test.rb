require "test_helper"
require_relative "base_test"

# The API shares its policies with the web app, so members and spectators must
# get the same narrow view over the API that they get in the browser.
class Api::V1::RolesTest < Api::V1::BaseTest
  setup do
    @admin = users(:organization_admin)
    @member = users(:organization_user)       # organization_one, access to project_1
    @spectator = users(:organization_spectator) # organization_one, access to project_1
    @project = projects(:project_1)
    @client = clients(:e_corp)
  end

  def ids(collection = json_response)
    collection.map { |item| item["id"] }.sort
  end

  # BaseTest#api_headers only yields a token the first time it is called for a
  # user (the plaintext cannot be read back), and these tests make several
  # requests per user.
  def api_headers(user, organization: nil)
    @tokens ||= {}
    @tokens[user.id] ||= user.regenerate_api_token!
    headers = { "Authorization" => "Bearer #{@tokens[user.id]}" }
    headers["X-Organization-Id"] = organization.id.to_s if organization
    headers
  end

  # -- Member ---------------------------------------------------------------

  test "member lists only the clients and tasks of their own projects" do
    get api_v1_clients_path, headers: api_headers(@member)
    assert_response :success
    assert_equal [ @client.id ], ids

    get api_v1_tasks_path, headers: api_headers(@member)
    assert_response :success
    assert_equal [ tasks(:debug).id ], ids
  end

  test "the project list is admin-only, but a granted project can still be shown" do
    # ProjectPolicy#index? is admin-only, unlike clients and tasks.
    get api_v1_projects_path, headers: api_headers(@member)
    assert_response :forbidden
    get api_v1_projects_path, headers: api_headers(@spectator)
    assert_response :forbidden

    get api_v1_projects_path, headers: api_headers(@admin)
    assert_response :success
    assert_equal @admin.current_organization.projects.kept.ids.sort, ids

    # show is admin-only as well; a member is not found, not forbidden, because the scope hides it
    get api_v1_project_path(@project), headers: api_headers(@member)
    assert_response :forbidden
    get api_v1_project_path(projects(:project_2)), headers: api_headers(@member)
    assert_response :not_found
  end

  test "member sees only themselves in the user list" do
    get api_v1_users_path, headers: api_headers(@member)
    assert_response :success
    assert_equal [ @member.id ], ids

    get api_v1_user_path(users(:joe)), headers: api_headers(@member)
    assert_response :not_found
  end

  test "member sees only their own time registrations" do
    get api_v1_time_regs_path, headers: api_headers(@member)
    assert_response :success
    assert_equal @member.time_regs.ids.sort, ids(json_response["time_regs"])

    get api_v1_time_reg_path(time_regs(:time_reg_1)), headers: api_headers(@member)
    assert_response :not_found

    patch api_v1_time_reg_path(time_regs(:time_reg_1)), params: { time_reg: { notes: "Hijacked" } }, headers: api_headers(@member)
    assert_response :not_found
    assert_not_equal "Hijacked", time_regs(:time_reg_1).reload.notes
  end

  test "member reports only cover their own time" do
    get api_v1_reports_path, headers: api_headers(@member)
    assert_response :success
    assert_equal @member.time_regs.count, json_response["total_entries"]
    assert_equal [ @member.id ], json_response["by_user"].map { |row| row["user_id"] }

    get detailed_api_v1_reports_path, headers: api_headers(@member)
    assert_response :success
    assert_equal @member.time_regs.sum(:minutes), json_response["total_minutes"]
  end

  test "member cannot manage clients or projects" do
    assert_no_difference("Client.count") do
      post api_v1_clients_path, params: { client: { name: "Sneaky" } }, headers: api_headers(@member)
    end
    assert_response :forbidden

    patch api_v1_client_path(@client), params: { client: { name: "Hijacked" } }, headers: api_headers(@member)
    assert_response :forbidden
    assert_not_equal "Hijacked", @client.reload.name

    delete api_v1_client_path(@client), headers: api_headers(@member)
    assert_response :forbidden
    assert @client.reload.kept?

    delete api_v1_project_path(@project), headers: api_headers(@member)
    assert_response :forbidden
    assert @project.reload.kept?

    assert_no_difference("Project.count") do
      post api_v1_projects_path, params: { project: { name: "Sneaky", client_id: @client.id, rate_currency: 0 } }, headers: api_headers(@member)
    end
    assert_response :forbidden
  end

  # -- Spectator ------------------------------------------------------------

  test "spectator can read reports for their projects but not the time registration endpoints" do
    get api_v1_reports_path, headers: api_headers(@spectator)
    assert_response :success
    assert_equal @project.time_regs.count, json_response["total_entries"]
    assert_equal [ @project.id ], json_response["by_project"].map { |row| row["project_id"] }

    get detailed_api_v1_reports_path, headers: api_headers(@spectator)
    assert_response :success

    get api_v1_time_regs_path, headers: api_headers(@spectator)
    assert_response :forbidden

    assert_no_difference("TimeReg.count") do
      post api_v1_time_regs_path,
        params: { time_reg: { date_worked: Date.today, minutes: 60, assigned_task_id: assigned_task(:task_1).id } },
        headers: api_headers(@spectator)
    end
    assert_response :forbidden

    put api_v1_time_reg_timer_path(time_regs(:time_reg_1)), headers: api_headers(@spectator)
    assert_response :not_found
  end

  test "spectator reads the clients, tasks and users of their projects" do
    get api_v1_clients_path, headers: api_headers(@spectator)
    assert_response :success
    assert_equal [ @client.id ], ids

    get api_v1_tasks_path, headers: api_headers(@spectator)
    assert_response :success
    assert_equal @project.assigned_tasks.map(&:task_id).uniq.sort, ids

    get api_v1_users_path, headers: api_headers(@spectator)
    assert_response :success
    assert_equal @project.time_regs.map(&:user_id).uniq.sort, ids
  end

  test "spectator cannot manage anything" do
    assert_no_difference("Client.count") do
      post api_v1_clients_path, params: { client: { name: "Sneaky" } }, headers: api_headers(@spectator)
    end
    assert_response :forbidden

    delete api_v1_project_path(@project), headers: api_headers(@spectator)
    assert_response :forbidden
    assert @project.reload.kept?
  end

  test "me works for every role" do
    [ @admin, @member, @spectator ].each do |user|
      get me_api_v1_users_path, headers: api_headers(user)
      assert_response :success
      assert_equal user.email, json_response["email"]
    end
  end

  # -- Organization header --------------------------------------------------

  test "an organization the user is not part of cannot be selected" do
    get api_v1_clients_path, headers: api_headers(@member, organization: organizations(:organization_two))
    assert_response :not_found
  end

  test "the role of the selected organization applies" do
    ron = users(:ron) # member in both organizations, active in organization_two, no projects there
    get api_v1_clients_path, headers: api_headers(ron)
    assert_response :success
    assert_empty ids

    get api_v1_clients_path, headers: api_headers(ron, organization: organizations(:organization_one))
    assert_response :success
    assert_equal [ @client.id ], ids, "ron has project access to project_1 in organization_one"

    get api_v1_reports_path, headers: api_headers(ron, organization: organizations(:organization_one))
    assert_response :success
    assert_equal ron.time_regs.joins(:organization).where(organizations: { id: organizations(:organization_one).id }).count, json_response["total_entries"]
  end
end
