require "test_helper"

# The relation scopes are where multi-tenant isolation actually happens, and
# each role takes a different SQL branch. Exercise every branch directly so a
# broken query (like the spectator branch that used to reference a missing
# column) fails here, with the policy named, rather than as a 500 on some page.
class ScopesByRoleTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:organization_one)
    @admin = users(:organization_admin)
    @member = users(:organization_user)       # access to project_1 only
    @member_without_projects = users(:joe)    # member of organization_one, no project access
    @spectator = users(:organization_spectator) # access to project_1 only
    @other_org_member = users(:ron)           # active in organization_two
    @project = projects(:project_1)
  end

  def scope(policy_class, relation, user, name: :default)
    policy_class.new(user: user).apply_scope(relation, type: :relation, name: name).to_a
  end

  # -- TimeReg -------------------------------------------------------------

  test "admin sees every time registration in the organization and nothing outside it" do
    result = scope(TimeRegPolicy, TimeReg.all, @admin)
    # Every fixture entry except the one logged in organization_two. (Not
    # Organization#time_regs: that association goes through users, and ron
    # belongs to both organizations.)
    assert_equal TimeReg.kept.where.not(id: time_regs(:time_reg_org_two)).sort, result.sort
    assert_not_includes result, time_regs(:time_reg_org_two)
  end

  test "member sees only their own time registrations" do
    assert_equal @member.time_regs.sort, scope(TimeRegPolicy, TimeReg.all, @member).sort
    assert_equal @member.time_regs.sort, scope(TimeRegPolicy, TimeReg.all, @member, name: :own).sort
  end

  test "spectator sees everyone's time on the projects they were granted, and nothing else" do
    result = scope(TimeRegPolicy, TimeReg.all, @spectator)
    assert_equal @project.time_regs.sort, result.sort
    assert_not_includes result, time_regs(:time_reg_6), "project_2 is not granted to the spectator"
    assert_not_includes result, time_regs(:time_reg_org_two)
    assert_empty scope(TimeRegPolicy, TimeReg.all, @spectator, name: :own)
  end

  test "a member active in another organization does not see this organization's time" do
    result = scope(TimeRegPolicy, TimeReg.all, @other_org_member)
    assert_equal [ time_regs(:time_reg_org_two) ], result
  end

  # -- User ----------------------------------------------------------------

  test "admin sees every user in the organization" do
    assert_equal @organization.users.sort, scope(UserPolicy, User.all, @admin).sort
  end

  test "member sees only themselves" do
    assert_equal [ @member ], scope(UserPolicy, User.all, @member)
  end

  test "spectator sees the users who logged time on their projects" do
    result = scope(UserPolicy, User.all, @spectator)
    assert_equal @project.time_regs.map(&:user).uniq.sort, result.sort
    assert_not_includes result, @spectator
    assert_not_includes result, @admin
  end

  # -- Project -------------------------------------------------------------

  test "admin sees every project in the organization" do
    assert_equal @organization.projects.kept.sort, scope(ProjectPolicy, Project.all, @admin).sort
  end

  test "member and spectator see only the projects they were granted" do
    assert_equal [ @project ], scope(ProjectPolicy, Project.all, @member)
    assert_equal [ @project ], scope(ProjectPolicy, Project.all, @spectator)
    assert_equal [ @project ], scope(ProjectPolicy, Project.all, @member, name: :own)
  end

  test "a member without project access sees no projects" do
    assert_empty scope(ProjectPolicy, Project.all, @member_without_projects)
  end

  test "project access in another organization does not leak in" do
    # ron has access to project_1 in organization_one but is active in organization_two
    assert_not_includes scope(ProjectPolicy, Project.all, @other_org_member), @project
  end

  # -- Client --------------------------------------------------------------

  test "admin sees every client, others only clients of their projects" do
    assert_equal @organization.clients.kept.sort, scope(ClientPolicy, Client.all, @admin).sort
    assert_equal [ clients(:e_corp) ], scope(ClientPolicy, Client.all, @member)
    assert_equal [ clients(:e_corp) ], scope(ClientPolicy, Client.all, @spectator)
    assert_empty scope(ClientPolicy, Client.all, @member_without_projects)
  end

  # -- Task ----------------------------------------------------------------

  test "admin sees every task in the organization" do
    assert_equal @organization.tasks.kept.sort, scope(TaskPolicy, Task.all, @admin).sort
  end

  test "member sees the tasks they logged time on, and may pick from their projects' tasks" do
    assert_equal [ tasks(:debug) ], scope(TaskPolicy, Task.all, @member)
    assert_equal @project.assigned_tasks.map(&:task).uniq.sort, scope(TaskPolicy, Task.all, @member, name: :own).sort
  end

  test "spectator sees the tasks of the projects they were granted" do
    assert_equal @project.assigned_tasks.map(&:task).uniq.sort, scope(TaskPolicy, Task.all, @spectator).sort
  end

  # -- Workspace scopes are admin-only -------------------------------------

  test "workspace scopes return nothing for members and spectators" do
    [ @member, @spectator ].each do |user|
      assert_empty scope(Workspace::ClientPolicy, Client.all, user)
      assert_empty scope(Workspace::ProjectPolicy, Project.all, user)
      assert_empty scope(Workspace::TaskPolicy, Task.all, user)
      assert_empty scope(Workspace::UserPolicy, User.all, user)
      assert_empty scope(Workspace::AccessInfoPolicy, AccessInfo.all, user)
      assert_empty scope(Workspace::ProjectAccessPolicy, ProjectAccess.all, user)
      assert_empty scope(Workspace::Projects::AssignedTaskPolicy, AssignedTask.all, user)
    end
  end

  test "workspace scopes are limited to the admin's organization" do
    assert_equal @organization.clients.kept.sort, scope(Workspace::ClientPolicy, Client.all, @admin).sort
    assert_equal @organization.projects.kept.sort, scope(Workspace::ProjectPolicy, Project.all, @admin).sort
    assert_equal @organization.users.sort, scope(Workspace::UserPolicy, User.all, @admin).sort
    assert_not_includes scope(Workspace::Projects::AssignedTaskPolicy, AssignedTask.all, @admin), assigned_task(:org_two_task)
  end

  # -- Rules that depend on the record -------------------------------------

  test "time registrations can only be opened and changed by their owner or an admin of the same organization" do
    own = time_regs(:time_reg_1_organization_user_1)
    someone_elses = time_regs(:time_reg_1)
    other_org = time_regs(:time_reg_org_two)

    %i[edit_modal? edit? update? destroy? toggle_active? show?].each do |rule|
      assert TimeRegPolicy.new(own, user: @member).apply(rule), "member should be allowed #{rule} on own entry"
      assert_not TimeRegPolicy.new(someone_elses, user: @member).apply(rule), "member should not be allowed #{rule} on a colleague's entry"
      assert TimeRegPolicy.new(someone_elses, user: @admin).apply(rule), "admin should be allowed #{rule} in own organization"
      assert_not TimeRegPolicy.new(other_org, user: @admin).apply(rule), "admin should not be allowed #{rule} in another organization"
      assert_not TimeRegPolicy.new(someone_elses, user: @spectator).apply(rule), "spectator should not be allowed #{rule}"
    end
  end

  test "spectators cannot enter the time registration screens" do
    %i[index? new_modal? update_tasks_select? export?].each do |rule|
      assert_not TimeRegPolicy.new(user: @spectator).apply(rule)
      assert TimeRegPolicy.new(user: @member).apply(rule)
      assert TimeRegPolicy.new(user: @admin).apply(rule)
    end
  end

  test "copies follow the same ownership rule as edits" do
    assert TimeReg::CopiesPolicy.new(time_regs(:time_reg_1_organization_user_1), user: @member).apply(:create?)
    assert_not TimeReg::CopiesPolicy.new(time_regs(:time_reg_1), user: @member).apply(:create?)
    assert TimeReg::CopiesPolicy.new(time_regs(:time_reg_1), user: @admin).apply(:create?)
    assert_not TimeReg::CopiesPolicy.new(time_regs(:time_reg_org_two), user: @admin).apply(:create?)
  end
end
