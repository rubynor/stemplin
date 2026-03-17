require "test_helper"

class DisconnectProjectShareServiceTest < ActiveSupport::TestCase
  def setup
    @project_share = project_shares(:project_one_shared_with_org_two)
    @project = projects(:project_1)
    @guest_org = organizations(:organization_two)
  end

  test "destroys the ProjectShare record" do
    assert_difference "ProjectShare.count", -1 do
      DisconnectProjectShareService.new(project_share: @project_share).call
    end

    assert_nil ProjectShare.find_by(id: @project_share.id)
  end

  test "cascades to destroy ProjectShareTaskRate records" do
    assert project_share_task_rates(:task_rate_one).present?

    assert_difference "ProjectShareTaskRate.count", -1 do
      DisconnectProjectShareService.new(project_share: @project_share).call
    end
  end

  test "destroys all ProjectAccess records for guest org users on this project" do
    # ron_org2_shared_project_1 is ron's org_two access to project_1
    ron_org2_access = project_accesses(:ron_org2_shared_project_1)
    assert ron_org2_access.present?

    DisconnectProjectShareService.new(project_share: @project_share).call

    assert_nil ProjectAccess.find_by(id: ron_org2_access.id)
  end

  test "does not destroy ProjectAccess records for the owning org users" do
    # ron_project_1 is ron's org_one access to project_1 (via access_info_3)
    ron_org1_access = project_accesses(:ron_project_1)
    spectator_access = project_accesses(:spectator_project_1)

    DisconnectProjectShareService.new(project_share: @project_share).call

    assert ProjectAccess.find_by(id: ron_org1_access.id), "Ron's org_one access should be preserved"
    assert ProjectAccess.find_by(id: spectator_access.id), "Spectator's access should be preserved"
  end

  test "cancels pending ProjectInvitation records for known guest org users" do
    # Create a user who belongs only to org_two (not org_one, which owns the project)
    guest_only_user = User.create!(
      email: "guest_only@example.com",
      first_name: "Guest",
      last_name: "Only",
      password: "password123",
      locale: "en"
    )
    AccessInfo.create!(
      user: guest_only_user,
      organization: @guest_org,
      role: :organization_user
    )

    # Create a pending invitation for this guest-org-only user
    invitation = ProjectInvitation.create!(
      project: @project,
      invited_email: guest_only_user.email,
      invited_by: users(:organization_admin),
      invited_at: Time.current
    )

    assert invitation.pending?

    DisconnectProjectShareService.new(project_share: @project_share).call

    invitation.reload
    assert invitation.rejected?, "Pending invitation for guest org user should be cancelled"
  end

  test "does not cancel invitations for users not in the guest org" do
    # Create a pending invitation for someone not in org_two
    invitation = ProjectInvitation.create!(
      project: @project,
      invited_email: "outsider@example.com",
      invited_by: users(:organization_admin),
      invited_at: Time.current
    )

    DisconnectProjectShareService.new(project_share: @project_share).call

    invitation.reload
    assert invitation.pending?, "Invitation for non-guest-org user should remain pending"
  end

  test "preserves TimeReg records" do
    time_reg_count = TimeReg.count

    DisconnectProjectShareService.new(project_share: @project_share).call

    assert_equal time_reg_count, TimeReg.count, "TimeReg records should be preserved"
  end

  test "works when called by org_one admin disconnecting a guest" do
    # This simulates org_one (project owner) disconnecting org_two
    assert_nothing_raised do
      DisconnectProjectShareService.new(project_share: @project_share).call
    end

    assert_nil ProjectShare.find_by(id: @project_share.id)
  end

  test "works when called by org_two admin disconnecting self" do
    # This simulates org_two (guest) disconnecting themselves
    # The service should work the same regardless of who initiates it
    assert_nothing_raised do
      DisconnectProjectShareService.new(project_share: @project_share).call
    end

    assert_nil ProjectShare.find_by(id: @project_share.id)
  end
end
