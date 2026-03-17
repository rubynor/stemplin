require "test_helper"

class Workspace::ProjectShareTaskRatePolicyTest < ActiveSupport::TestCase
  fixtures :all

  setup do
    @task_rate = project_share_task_rates(:task_rate_one)
    @project_share = project_shares(:project_one_shared_with_org_two)
    @org_one = organizations(:organization_one)
    @org_two = organizations(:organization_two)
  end

  # Helper to build a policy instance for a given user and record
  def policy_for(user, record = @task_rate)
    Workspace::ProjectShareTaskRatePolicy.new(record, user: user)
  end

  # Helper to switch a user's active context to a given organization
  def switch_org_context!(user, organization)
    user.access_infos.update_all(active: false)
    user.access_infos.find_by(organization: organization).update!(active: true)
  end

  # --- create? ---

  test "create? allowed for org_two admin (guest org)" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization
    assert policy_for(admin).apply(:create?)
  end

  test "create? denied for org_one admin (project owner)" do
    admin = users(:organization_admin)
    assert_equal @org_one, admin.current_organization
    assert_not policy_for(admin).apply(:create?)
  end

  test "create? denied for non-admin user in org_two" do
    ron = users(:ron)
    assert_equal @org_two, ron.current_organization
    assert_not policy_for(ron).apply(:create?)
  end

  test "create? denied for non-admin user in org_one" do
    joe = users(:joe)
    assert_equal @org_one, joe.current_organization
    assert_not policy_for(joe).apply(:create?)
  end

  # --- update? ---

  test "update? allowed for org_two admin (guest org)" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization
    assert policy_for(admin).apply(:update?)
  end

  test "update? denied for org_one admin (project owner)" do
    admin = users(:organization_admin)
    assert_equal @org_one, admin.current_organization
    assert_not policy_for(admin).apply(:update?)
  end

  test "update? denied for non-admin user in org_two" do
    ron = users(:ron)
    assert_equal @org_two, ron.current_organization
    assert_not policy_for(ron).apply(:update?)
  end

  # --- destroy? ---

  test "destroy? allowed for org_two admin (guest org)" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization
    assert policy_for(admin).apply(:destroy?)
  end

  test "destroy? denied for org_one admin (project owner)" do
    admin = users(:organization_admin)
    assert_equal @org_one, admin.current_organization
    assert_not policy_for(admin).apply(:destroy?)
  end

  test "destroy? denied for non-admin user in org_two" do
    ron = users(:ron)
    assert_equal @org_two, ron.current_organization
    assert_not policy_for(ron).apply(:destroy?)
  end

  # --- scope ---

  test "scope returns task rates for admin of org_two (guest org)" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)

    policy = Workspace::ProjectShareTaskRatePolicy.new(user: admin)
    scope = policy.apply_scope(ProjectShareTaskRate.all, type: :relation)

    assert_includes scope, @task_rate
  end

  test "scope returns empty for admin of org_one (project owner has no task rates)" do
    admin = users(:organization_admin)
    # Active in org_one by default

    policy = Workspace::ProjectShareTaskRatePolicy.new(user: admin)
    scope = policy.apply_scope(ProjectShareTaskRate.all, type: :relation)

    assert_not_includes scope, @task_rate
  end

  test "scope returns empty for non-admin user" do
    joe = users(:joe)

    policy = Workspace::ProjectShareTaskRatePolicy.new(user: joe)
    scope = policy.apply_scope(ProjectShareTaskRate.all, type: :relation)

    assert_empty scope
  end
end
