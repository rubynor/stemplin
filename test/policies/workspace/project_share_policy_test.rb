require "test_helper"

class Workspace::ProjectSharePolicyTest < ActiveSupport::TestCase
  fixtures :all

  setup do
    @project_share = project_shares(:project_one_shared_with_org_two)
    @org_one = organizations(:organization_one)
    @org_two = organizations(:organization_two)
  end

  # Helper to build a policy instance for a given user and record
  def policy_for(user, record = @project_share)
    Workspace::ProjectSharePolicy.new(record, user: user)
  end

  # Helper to switch a user's active context to a given organization
  def switch_org_context!(user, organization)
    user.access_infos.update_all(active: false)
    user.access_infos.find_by(organization: organization).update!(active: true)
  end

  # --- show? ---

  test "show? allowed for org_one admin (project owner)" do
    admin = users(:organization_admin)
    # organization_admin is active in org_one by default
    assert_equal @org_one, admin.current_organization
    assert policy_for(admin).apply(:show?)
  end

  test "show? allowed for org_two admin (guest org)" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization
    assert policy_for(admin).apply(:show?)
  end

  test "show? denied for non-admin user in org_one" do
    joe = users(:joe)
    assert_equal @org_one, joe.current_organization
    assert_not policy_for(joe).apply(:show?)
  end

  test "show? denied for non-admin user in org_two" do
    ron = users(:ron)
    assert_equal @org_two, ron.current_organization
    assert_not policy_for(ron).apply(:show?)
  end

  # --- update? ---

  test "update? allowed for org_two admin (guest org managing rates)" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization
    assert policy_for(admin).apply(:update?)
  end

  test "update? denied for org_one admin (project owner cannot manage guest rates)" do
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

  test "destroy? allowed for org_one admin (project owner)" do
    admin = users(:organization_admin)
    assert_equal @org_one, admin.current_organization
    assert policy_for(admin).apply(:destroy?)
  end

  test "destroy? allowed for org_two admin (guest org)" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)
    assert_equal @org_two, admin.current_organization
    assert policy_for(admin).apply(:destroy?)
  end

  test "destroy? denied for non-admin user in org_one" do
    joe = users(:joe)
    assert_equal @org_one, joe.current_organization
    assert_not policy_for(joe).apply(:destroy?)
  end

  test "destroy? denied for non-admin user in org_two" do
    ron = users(:ron)
    assert_equal @org_two, ron.current_organization
    assert_not policy_for(ron).apply(:destroy?)
  end

  # --- scope ---

  test "scope returns project_shares for admin of org_two (guest org)" do
    admin = users(:organization_admin)
    switch_org_context!(admin, @org_two)

    policy = Workspace::ProjectSharePolicy.new(user: admin)
    scope = policy.apply_scope(ProjectShare.all, type: :relation)

    assert_includes scope, @project_share
  end

  test "scope returns project_shares for admin of org_one (project owner)" do
    admin = users(:organization_admin)
    # Active in org_one by default

    policy = Workspace::ProjectSharePolicy.new(user: admin)
    scope = policy.apply_scope(ProjectShare.all, type: :relation)

    assert_includes scope, @project_share
  end

  test "scope returns empty for non-admin user" do
    joe = users(:joe)

    policy = Workspace::ProjectSharePolicy.new(user: joe)
    scope = policy.apply_scope(ProjectShare.all, type: :relation)

    assert_empty scope
  end
end
