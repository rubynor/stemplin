require "test_helper"

class ProjectShareTest < ActiveSupport::TestCase
  setup do
    @project = projects(:project_1) # owned by organization_one
    @customer = organizations(:customer_org)
    @share = ProjectShare.create!(project: @project, invited_email: " Customer_Admin@Example.com ", invited_by: users(:organization_admin))
  end

  test "an invitation starts pending, with a token, an expiry and a normalized email" do
    assert @share.pending?
    assert @share.invitation_token.present?
    assert_in_delta ProjectShare::EXPIRES_IN.from_now, @share.expires_at, 5.seconds
    assert_equal "customer_admin@example.com", @share.invited_email
    assert @share.acceptable?
  end

  test "accepting puts the project into the chosen organization" do
    @share.accept!(@customer)

    assert @share.reload.accepted?
    assert_equal @customer, @share.organization
    assert_not_nil @share.accepted_at
    assert_includes Project.shared_with(@customer), @project
  end

  test "a project cannot be shared into the organization that owns it" do
    assert_raises(ActiveRecord::RecordInvalid) { @share.accept!(@project.organization) }
    assert_empty Project.shared_with(@project.organization)
  end

  test "the same organization cannot hold two live shares of one project" do
    @share.accept!(@customer)
    second = ProjectShare.create!(project: @project, invited_email: "someone@example.com", invited_by: users(:organization_admin))

    assert_raises(ActiveRecord::RecordInvalid) { second.accept!(@customer) }
  end

  test "an address can only have one open invitation per project" do
    duplicate = ProjectShare.new(project: @project, invited_email: "customer_admin@example.com", invited_by: users(:organization_admin))
    assert_not duplicate.valid?
    assert duplicate.errors.added?(:invited_email, :taken, value: "customer_admin@example.com")

    @share.revoke!
    assert duplicate.valid?, "a cancelled invitation should not block a new one"
  end

  test "someone who only belongs to the owning organization cannot be invited" do
    share = ProjectShare.new(project: @project, invited_email: users(:joe).email, invited_by: users(:organization_admin))

    assert_not share.valid?
    assert share.errors.added?(:invited_email, :only_in_owner)
  end

  test "members of the owning organization with other organizations, and unknown addresses, can be invited" do
    assert ProjectShare.new(project: @project, invited_email: users(:ron).email, invited_by: users(:organization_admin)).valid?
    assert ProjectShare.new(project: @project, invited_email: "new@example.com", invited_by: users(:organization_admin)).valid?
  end

  test "an invalid email is rejected" do
    assert_not ProjectShare.new(project: @project, invited_email: "not-an-email", invited_by: users(:organization_admin)).valid?
  end

  test "an expired invitation can be neither accepted nor rejected" do
    @share.update!(expires_at: 1.minute.ago)

    assert @share.expired?
    assert_not @share.acceptable?
    assert_raises(ArgumentError) { @share.accept!(@customer) }
    assert_raises(ArgumentError) { @share.reject! }
  end

  test "revoking an accepted share takes the project away again" do
    @share.accept!(@customer)
    @share.revoke!

    assert @share.revoked?
    assert_not_nil @share.revoked_at
    assert_empty Project.shared_with(@customer)
  end

  test "pending, rejected and revoked shares give no access" do
    assert_empty Project.shared_with(@customer)
    @share.reject!
    assert_empty Project.shared_with(@customer)
  end

  test "listed covers live shares and open invitations only" do
    expired = ProjectShare.create!(project: @project, invited_email: "late@example.com", invited_by: users(:organization_admin), expires_at: 1.minute.ago)
    rejected = ProjectShare.create!(project: @project, invited_email: "no@example.com", invited_by: users(:organization_admin))
    rejected.reject!

    assert_equal [ @share ], ProjectShare.listed.to_a
    @share.accept!(@customer)
    assert_equal [ @share ], ProjectShare.listed.to_a
    assert_not_includes ProjectShare.listed, expired
  end

  test "a discarded project is no longer shared" do
    @share.accept!(@customer)
    @project.discard

    assert_empty Project.shared_with(@customer)
  end
end
