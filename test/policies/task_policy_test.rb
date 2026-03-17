require "test_helper"

class TaskPolicyTest < ActiveSupport::TestCase
  fixtures :all

  setup do
    @org_one = organizations(:organization_one)
    @org_two = organizations(:organization_two)

    # Tasks belonging to org_one
    @debug = tasks(:debug)             # assigned to project_1 (shared with org_two)
    @coding = tasks(:coding)           # assigned to project_1 (shared with org_two)
    @authentication = tasks(:authentication) # assigned to project_1 (shared with org_two)
    @ux_audit = tasks(:ux_audit)       # assigned to project_2 (NOT shared with org_two)
    @e2e_testing = tasks(:e2e_testing) # org_one, no assigned_tasks on shared projects

    # Task belonging to org_two
    @login = tasks(:login)
  end

  # Helper to get the default scope result for a given user
  def scoped_tasks(user)
    policy = TaskPolicy.new(user: user)
    policy.apply_scope(Task.all, type: :relation)
  end

  # --- Scope: org_two admin sees tasks assigned to shared projects ---

  test "scope: org_two admin sees tasks assigned to shared projects (org_one's tasks)" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    result = scoped_tasks(admin)

    # Should see org_two's own tasks
    assert_includes result, @login

    # Should see org_one tasks assigned to project_1 (shared with org_two)
    assert_includes result, @debug
    assert_includes result, @coding
    assert_includes result, @authentication
  end

  test "scope: org_two admin does NOT see org_one tasks not assigned to shared projects" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    result = scoped_tasks(admin)

    # ux_audit is assigned to project_2 which is NOT shared with org_two
    assert_not_includes result, @ux_audit

    # e2e_testing belongs to org_one and has no assigned_tasks on shared projects
    assert_not_includes result, @e2e_testing
  end

  # --- Scope: org_two member with ProjectAccess sees tasks on shared projects ---

  test "scope: org_two member with ProjectAccess sees tasks on their shared projects" do
    ron = users(:ron)
    # ron is active in org_two by default and has ProjectAccess to project_1 via access_info_2
    assert_equal @org_two, ron.current_organization

    result = scoped_tasks(ron)

    # Should see tasks assigned to project_1 (shared project ron has access to)
    assert_includes result, @debug
    assert_includes result, @coding
    assert_includes result, @authentication
  end

  test "scope: org_two member does NOT see org_one tasks not on shared projects" do
    ron = users(:ron)
    assert_equal @org_two, ron.current_organization

    result = scoped_tasks(ron)

    # ux_audit is assigned to project_2 which is NOT shared with org_two
    assert_not_includes result, @ux_audit

    # e2e_testing belongs to org_one, not assigned to any shared project
    assert_not_includes result, @e2e_testing
  end

  # --- Scope: org_one admin still sees all their own tasks ---

  test "scope: org_one admin sees all org_one tasks" do
    admin = users(:organization_admin)
    # admin is active in org_one by default
    assert_equal @org_one, admin.current_organization

    result = scoped_tasks(admin)

    assert_includes result, @debug
    assert_includes result, @coding
    assert_includes result, @authentication
    assert_includes result, @ux_audit
    assert_includes result, @e2e_testing
    assert_not_includes result, @login
  end
end
