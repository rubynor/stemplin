require "test_helper"

class TimeRegPolicyTest < ActiveSupport::TestCase
  fixtures :all

  setup do
    @org_one = organizations(:organization_one)
    @org_two = organizations(:organization_two)
    @project_1 = projects(:project_1)          # belongs to org_one, shared with org_two
    @time_reg_joe = time_regs(:time_reg_1)     # user=joe, project_1 (org_one's project)
    @time_reg_ron = time_regs(:time_reg_2)     # user=ron, project_1 (org_one's project)
  end

  # Helper to build a policy instance for a given user and record
  def policy_for(user, record)
    TimeRegPolicy.new(record, user: user)
  end

  # Helper to get the default scope result for a given user
  def scoped_time_regs(user)
    policy = TimeRegPolicy.new(user: user)
    policy.apply_scope(TimeReg.all, type: :relation)
  end

  # Helper to switch a user's active context to a given organization
  def switch_org_context!(user, organization)
    user.access_infos.update_all(active: false)
    user.access_infos.find_by(organization: organization).update!(active: true)
  end

  # --- create? ---

  test "create? org_two member can create their own time_reg on shared project" do
    ron = users(:ron)
    # ron is active in org_two by default
    assert_equal @org_two, ron.current_organization

    # Build a new time_reg for ron on the shared project
    new_time_reg = TimeReg.new(
      user: ron,
      assigned_task: assigned_task(:task_1),
      date_worked: Date.today,
      minutes: 60
    )

    assert policy_for(ron, new_time_reg).apply(:create?)
  end

  test "create? org_two admin CANNOT create time_regs on shared project (admin path checks same_organization)" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    new_time_reg = TimeReg.new(
      user: admin,
      assigned_task: assigned_task(:task_1),
      date_worked: Date.today,
      minutes: 60
    )

    # Admin path checks same_organization which fails because project belongs to org_one
    assert_not policy_for(admin, new_time_reg).apply(:create?)
  end

  # --- show? ---

  test "show? org_two admin can view any time_reg on shared project" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    # Can see joe's time_reg on the shared project (not admin's own entry)
    assert policy_for(admin, @time_reg_joe).apply(:show?)
  end

  # --- edit?/update?/destroy? ---

  test "edit? org_two admin CANNOT edit org_one user's time_reg on shared project" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    assert_not policy_for(admin, @time_reg_joe).apply(:edit?)
  end

  test "update? org_two admin CANNOT update org_one user's time_reg on shared project" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    assert_not policy_for(admin, @time_reg_joe).apply(:update?)
  end

  test "destroy? org_two admin CANNOT destroy org_one user's time_reg on shared project" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    assert_not policy_for(admin, @time_reg_joe).apply(:destroy?)
  end

  test "edit? org_two member CAN edit their own time_reg on shared project" do
    ron = users(:ron)
    assert_equal @org_two, ron.current_organization

    assert policy_for(ron, @time_reg_ron).apply(:edit?)
  end

  test "update? org_two member CAN update their own time_reg on shared project" do
    ron = users(:ron)
    assert_equal @org_two, ron.current_organization

    assert policy_for(ron, @time_reg_ron).apply(:update?)
  end

  test "destroy? org_two member CAN destroy their own time_reg on shared project" do
    ron = users(:ron)
    assert_equal @org_two, ron.current_organization

    assert policy_for(ron, @time_reg_ron).apply(:destroy?)
  end

  # --- Scope (default) ---

  test "scope: org_two admin sees all time_regs on shared projects" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    result = scoped_time_regs(admin)

    # Should see time_regs from the shared project (project_1)
    assert_includes result, @time_reg_joe
    assert_includes result, @time_reg_ron
  end

  test "scope: org_two member sees only their own time_regs" do
    ron = users(:ron)
    assert_equal @org_two, ron.current_organization

    result = scoped_time_regs(ron)

    # Ron should see his own time_regs
    assert_includes result, @time_reg_ron

    # Ron should NOT see joe's time_regs
    assert_not_includes result, @time_reg_joe
  end
end
