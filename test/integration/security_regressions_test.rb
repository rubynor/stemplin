require "test_helper"

# One test per hole found in the security audit, so none of them can quietly
# come back.
class SecurityRegressionsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  TURBO_STREAM = { "Accept" => "text/vnd.turbo-stream.html, text/html" }.freeze
  XSS = "<img src=x onerror=alert(1)>".freeze

  setup do
    @admin = users(:organization_admin)
    @member = users(:joe)
    @organization = organizations(:organization_one)
    @foreign_assigned_task = assigned_task(:org_two_task)
    @time_reg = time_regs(:time_reg_1)
  end

  test "an admin cannot hand out the super_admin role" do
    sign_in @admin
    access_info = @member.access_info(@organization)

    patch workspace_team_member_path(@member), params: { user: { role: "super_admin" } }, headers: TURBO_STREAM

    assert_equal "organization_user", access_info.reload.role
  end

  test "an admin cannot give a member access to another organization's project" do
    sign_in @admin

    patch workspace_team_member_path(@member),
      params: { user: { role: "organization_user", project_ids: [ projects(:org_two_project).id, projects(:project_1).id ] } },
      headers: TURBO_STREAM

    assert_equal [ projects(:project_1) ], @member.access_info(@organization).projects.to_a
  end

  test "names in the report filters are escaped" do
    @member.update_columns(first_name: XSS)
    clients(:e_corp).update_columns(name: XSS)
    sign_in @admin

    get detailed_reports_path

    assert_response :success
    assert_not_includes response.body, XSS
    assert_includes response.body, ERB::Util.html_escape(XSS)
  end

  test "a time reg cannot be moved to another organization's task" do
    sign_in @member

    patch time_reg_path(@time_reg), params: { time_reg: { assigned_task_id: @foreign_assigned_task.id } }

    assert_equal assigned_task(:task_1), @time_reg.reload.assigned_task
  end

  test "a member cannot register time on a project they have no access to" do
    sign_in @member
    assert_empty @member.access_info(@organization).projects

    assert_no_difference -> { TimeReg.count } do
      post time_regs_path, params: { time_reg: { date_worked: Date.today, minutes: 60, assigned_task_id: assigned_task(:task_1).id } }
    end
  end

  test "a member cannot hand their time reg to someone else" do
    sign_in @member

    patch time_reg_path(@time_reg), params: { provide_user: "true", time_reg: { user_id: @admin.id, minutes: 5 } }

    assert_equal @member, @time_reg.reload.user
    assert_equal 120, @time_reg.minutes
  end

  test "a member cannot take over someone else's time reg" do
    others_time_reg = time_regs(:time_reg_2)
    sign_in @member

    patch time_reg_path(others_time_reg), params: { provide_user: "true", time_reg: { user_id: @member.id } }

    assert_equal users(:ron), others_time_reg.reload.user
  end

  test "an admin cannot register time for someone outside the organization" do
    outsider = users(:customer_member)
    sign_in @admin

    assert_no_difference -> { TimeReg.count } do
      post time_regs_path, params: { provide_user: "true",
        time_reg: { user_id: outsider.id, date_worked: Date.today, minutes: 60, assigned_task_id: assigned_task(:task_1).id } }
    end
  end

  test "an admin can still register time for a member of the organization" do
    sign_in @admin

    assert_difference -> { @member.time_regs.count } do
      post time_regs_path, params: { provide_user: "true",
        time_reg: { user_id: @member.id, date_worked: Date.today, minutes: 60, assigned_task_id: assigned_task(:task_1).id } }
    end
  end

  test "a project cannot be moved to another organization's client" do
    project = projects(:project_1)
    sign_in @admin

    patch workspace_project_path(project), params: { project: { client_id: clients(:f_corp).id } }

    assert_redirected_to root_path
    assert_equal clients(:e_corp), project.reload.client
  end

  test "a project cannot use another organization's task" do
    project = projects(:project_1)
    sign_in @admin

    assert_no_difference -> { AssignedTask.count } do
      patch workspace_project_path(project), params: { project: { assigned_tasks_attributes: [ { task_id: tasks(:login).id, rate: 0 } ] } }
    end
    assert_redirected_to root_path
  end

  test "a task created with a project always lands in the current organization" do
    project = projects(:project_1)
    sign_in @admin

    assert_difference -> { @organization.tasks.count } do
      patch workspace_project_path(project), params: { project: { assigned_tasks_attributes: [
        { rate: 0, task_attributes: { name: "Smuggled task", organization_id: organizations(:organization_two).id } }
      ] } }
    end
    assert_equal @organization, Task.find_by!(name: "Smuggled task").organization
  end

  test "the onboarding wizard does not let a member create clients, projects or tasks" do
    sign_in @member

    assert_no_difference [ -> { Client.count }, -> { Project.count }, -> { Task.count } ] do
      patch "/onboarding_wizard/client", params: { client: { name: "Sneaky client" } }
      assert_redirected_to root_path
      patch "/onboarding_wizard/project", params: { project: { name: "Sneaky project" } }
      assert_redirected_to root_path
      patch "/onboarding_wizard/tasks", params: { task: { name: "Sneaky task" } }
      assert_redirected_to root_path
    end
  end

  test "the time reg export keeps spreadsheet formulas as text" do
    @time_reg.update_columns(notes: "=HYPERLINK(\"http://evil.example\")")
    sign_in @admin

    get export_time_regs_path(project_id: projects(:project_1).id)

    assert_response :success
    assert_includes response.body, "'=HYPERLINK"
  end

  test "password reset answers the same for a known and an unknown address" do
    post user_password_path, params: { user: { email: @member.email } }
    known = [ response.status, response.location, flash[:notice] ]

    post user_password_path, params: { user: { email: "nobody@example.com" } }
    unknown = [ response.status, response.location, flash[:notice] ]

    assert_equal known, unknown
  end

  test "a password shorter than eight characters is refused" do
    assert_no_difference -> { User.count } do
      post user_registration_path, params: { user: { locale: "en", first_name: "Short", last_name: "Password",
        email: "short@example.com", password: "1234567", password_confirmation: "1234567" } }
    end
  end
end
