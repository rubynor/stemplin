require "test_helper"

# Sharing a project must only ever open the read-only Shared:: views. Every scope the rest of the app
# uses has to behave exactly as if the share did not exist.
class SharedProjectScopesTest < ActiveSupport::TestCase
  setup do
    @project = projects(:project_1)
    @customer = organizations(:customer_org)
    @customer_admin = users(:customer_admin)
    @customer_member = users(:customer_member)

    share = ProjectShare.create!(project: @project, invited_email: @customer_admin.email, invited_by: users(:organization_admin))
    share.accept!(@customer)
  end

  def scope(policy_class, relation, user, name: :default)
    policy_class.new(user: user).apply_scope(relation, type: :relation, name: name).to_a
  end

  test "the customer's admin sees the shared project and its time, and nothing else" do
    assert_equal [ @project ], scope(Shared::ProjectPolicy, Project.all, @customer_admin)
    assert_equal @project.time_regs.sort, scope(Shared::TimeRegPolicy, TimeReg.all, @customer_admin).sort
    assert_not_includes scope(Shared::TimeRegPolicy, TimeReg.all, @customer_admin), time_regs(:time_reg_6), "project_2 is not shared"
  end

  test "the customer's other members see nothing shared" do
    assert_empty scope(Shared::ProjectPolicy, Project.all, @customer_member)
    assert_empty scope(Shared::TimeRegPolicy, TimeReg.all, @customer_member)
  end

  test "the owner does not see its own project as shared" do
    assert_empty scope(Shared::ProjectPolicy, Project.all, users(:organization_admin))
  end

  test "a share does not leak into any of the app's regular scopes" do
    assert_empty scope(ProjectPolicy, Project.all, @customer_admin)
    assert_empty scope(ProjectPolicy, Project.all, @customer_admin, name: :own)
    assert_empty scope(Workspace::ProjectPolicy, Project.all, @customer_admin)
    assert_empty scope(TimeRegPolicy, TimeReg.all, @customer_admin)
    assert_empty scope(TimeRegPolicy, TimeReg.all, @customer_admin, name: :own)
    assert_empty scope(ClientPolicy, Client.all, @customer_admin)
    assert_empty scope(TaskPolicy, Task.all, @customer_admin)
    assert_equal [ @customer_admin, @customer_member ].sort, scope(UserPolicy, User.all, @customer_admin).sort
  end

  test "the customer cannot change the shared project or its time" do
    time_reg = time_regs(:time_reg_1)
    %i[update? destroy? toggle_active? edit_modal?].each do |rule|
      assert_not TimeRegPolicy.new(time_reg, user: @customer_admin).apply(rule), "TimeRegPolicy##{rule}"
    end
    %i[show? edit? update? destroy?].each do |rule|
      assert_not Workspace::ProjectPolicy.new(@project, user: @customer_admin).apply(rule), "Workspace::ProjectPolicy##{rule}"
    end
  end

  test "only the owner's admins can see and manage the project's shares" do
    shares = ProjectShare.where(project: @project)
    assert_equal shares.sort, scope(Workspace::ProjectSharePolicy, shares, users(:organization_admin)).sort
    assert_empty scope(Workspace::ProjectSharePolicy, shares, users(:organization_user))
    assert_empty scope(Workspace::ProjectSharePolicy, shares, @customer_admin)
    assert_not Workspace::ProjectSharePolicy.new(shares.first, user: @customer_admin).apply(:destroy?)
  end
end
