require "test_helper"

class Workspace::ProjectPolicyTest < ActiveSupport::TestCase
  fixtures :all

  setup do
    @org_one = organizations(:organization_one)
    @org_two = organizations(:organization_two)
    @project_1 = projects(:project_1) # belongs to org_one, shared with org_two
    @project_2 = projects(:project_2) # belongs to org_one, NOT shared
  end

  # Helper to build a policy instance for a given user and record
  def policy_for(user, record = Project)
    Workspace::ProjectPolicy.new(record, user: user)
  end

  # Helper to get the scope result for a given user
  def scoped_projects(user)
    policy = Workspace::ProjectPolicy.new(user: user)
    policy.apply_scope(Project.all, type: :relation)
  end

  # --- Scope tests ---

  test "scope: org_one admin sees all org_one projects" do
    admin = users(:organization_admin)
    # active in org_one by default
    assert_equal @org_one, admin.current_organization

    result = scoped_projects(admin)

    assert_includes result, @project_1
    assert_includes result, @project_2
  end

  test "scope: org_two admin sees projects shared with org_two" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    result = scoped_projects(admin)

    assert_includes result, @project_1
  end

  test "scope: org_two admin does NOT see org_one projects that are not shared" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    result = scoped_projects(admin)

    assert_not_includes result, @project_2
  end

  test "scope: org_two non-admin with ProjectAccess sees shared project" do
    ron = users(:ron)
    # ron is active in org_two by default (access_info_2)
    assert_equal @org_two, ron.current_organization

    # ron has ProjectAccess to project_1 via access_info_2 (ron_org2_shared_project_1 fixture)
    result = scoped_projects(ron)

    assert_includes result, @project_1
  end

  test "scope: org_two non-admin without ProjectAccess does NOT see shared project" do
    org_user = users(:organization_user)
    switch_org_context!(org_user, @org_two)
    assert_equal @org_two, org_user.current_organization

    # organization_user has no ProjectAccess to project_1 in org_two
    result = scoped_projects(org_user)

    assert_not_includes result, @project_1
  end

  test "scope: org_one non-admin with ProjectAccess sees own org project" do
    ron = users(:ron)
    switch_org_context!(ron, @org_one)
    assert_equal @org_one, ron.current_organization

    # ron has ProjectAccess to project_1 via access_info_3 (ron_project_1 fixture)
    result = scoped_projects(ron)

    assert_includes result, @project_1
  end

  test "scope: org_one non-admin without ProjectAccess does NOT see own org project" do
    ron = users(:ron)
    switch_org_context!(ron, @org_one)
    assert_equal @org_one, ron.current_organization

    # ron does NOT have ProjectAccess to project_2
    result = scoped_projects(ron)

    assert_not_includes result, @project_2
  end

  # --- show? tests ---

  test "show? allows org_one admin to view own project" do
    admin = users(:organization_admin)
    assert_equal @org_one, admin.current_organization

    assert policy_for(admin, @project_1).apply(:show?)
  end

  test "show? allows org_two admin to view shared project (read-only)" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    assert policy_for(admin, @project_1).apply(:show?)
  end

  test "show? denies org_two admin for non-shared project" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    assert_not policy_for(admin, @project_2).apply(:show?)
  end

  # --- edit?/update?/destroy? tests ---

  test "edit? denies org_two admin for shared project" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    assert_not policy_for(admin, @project_1).apply(:edit?)
  end

  test "update? denies org_two admin for shared project" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    assert_not policy_for(admin, @project_1).apply(:update?)
  end

  test "destroy? denies org_two admin for shared project" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization

    assert_not policy_for(admin, @project_1).apply(:destroy?)
  end

  test "edit? allows org_one admin for own project" do
    admin = users(:organization_admin)
    assert_equal @org_one, admin.current_organization

    assert policy_for(admin, @project_1).apply(:edit?)
  end

  test "update? allows org_one admin for own project" do
    admin = users(:organization_admin)
    assert_equal @org_one, admin.current_organization

    assert policy_for(admin, @project_1).apply(:update?)
  end

  test "destroy? allows org_one admin for own project" do
    admin = users(:organization_admin)
    assert_equal @org_one, admin.current_organization

    assert policy_for(admin, @project_1).apply(:destroy?)
  end
end
