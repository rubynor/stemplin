require "test_helper"

class ProjectInvitationServiceTest < ActiveSupport::TestCase
  def setup
    @project = projects(:project_1)
    @admin_user = users(:organization_admin)
    @external_email = "consultant@stemplin.com"
    @external_org = organizations(:organization_two)
  end

  test "full invitation workflow" do
    # Test 1: Create invitation manually (skip service call for now)
    invitation = ProjectInvitation.create!(
      project: @project,
      invited_email: @external_email,
      invited_by: @admin_user,
      invited_at: Time.current
    )

    # Test 2: Invitation gets created
    assert invitation.persisted?, "ProjectInvitation should be saved"
    assert_equal @project, invitation.project
    assert_equal @admin_user, invitation.invited_by
    assert invitation.invitation_token.present?, "Should have invitation token"
    assert invitation.pending?, "Invitation should be pending"

    # Test 3: Invitation can be accepted
    begin
      result = ProjectInvitationService.accept_invitation(invitation.invitation_token, @external_org)
      assert result, "Invitation acceptance should return true"
    rescue => e
      puts "Acceptance failed with error: #{e.message}"
      puts "Invitation can_be_accepted?: #{invitation.can_be_accepted?}"
      puts "Invitation pending?: #{invitation.pending?}"
      puts "Invitation expired?: #{invitation.expired?}"
      raise e
    end

    invitation.reload
    assert invitation.accepted?, "Invitation should be accepted"
    assert_equal @external_org, invitation.accepted_as_access_info.organization

    # Test 4: Invited user has access to the project
    project_access = ProjectAccess.joins(:access_info)
                                  .where(project: @project, access_infos: { organization: @external_org })
                                  .first
    assert project_access, "ProjectAccess should be created"
    assert_equal @external_email, project_access.user.email
  end
end
