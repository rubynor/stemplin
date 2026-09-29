require "test_helper"

# The whole sharing flow over HTTP: the owner invites, the customer's admin accepts and reads the
# project, and neither side can reach further than that.
class ProjectSharingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActionMailer::TestHelper

  setup do
    @owner_admin = users(:organization_admin) # active in organization_one, which owns project_1
    @customer_admin = users(:customer_admin)
    @customer = organizations(:customer_org)
    @project = projects(:project_1)
    @period = { time_frame: "custom", start_date: Date.today - 7, end_date: Date.today }
  end

  def invite(email = @customer_admin.email)
    sign_in @owner_admin
    post workspace_project_shares_path(@project), params: { project_share: { invited_email: email } }
    sign_out @owner_admin
    ProjectShare.order(:created_at).last
  end

  def accepted_share
    share = invite
    share.accept!(@customer)
    share
  end

  test "the owner invites a customer and sees the invitation on the project" do
    sign_in @owner_admin
    assert_difference -> { ProjectShare.pending.count } do
      assert_enqueued_emails 1 do
        post workspace_project_shares_path(@project), params: { project_share: { invited_email: @customer_admin.email } }
      end
    end
    assert_redirected_to workspace_project_path(@project, tab: "sharing")

    get workspace_project_path(@project, tab: "sharing")
    assert_response :success
    assert_includes response.body, @customer_admin.email
    assert_includes response.body, ProjectShare.last.invitation_token
  end

  test "an invalid email is not saved" do
    sign_in @owner_admin
    assert_no_difference -> { ProjectShare.count } do
      post workspace_project_shares_path(@project), params: { project_share: { invited_email: "nope" } }
    end
    assert_redirected_to workspace_project_path(@project, tab: "sharing")
  end

  test "only the owner's admins can share a project" do
    sign_in users(:organization_user)
    assert_no_difference -> { ProjectShare.count } do
      post workspace_project_shares_path(@project), params: { project_share: { invited_email: @customer_admin.email } }
    end

    sign_in @customer_admin
    assert_no_difference -> { ProjectShare.count } do
      post workspace_project_shares_path(@project), params: { project_share: { invited_email: "x@example.com" } }
    end
  end

  test "the invited admin accepts into their organization and lands on the shared project" do
    share = invite
    sign_in @customer_admin

    get project_share_invitation_path(share.invitation_token)
    assert_response :success
    assert_includes response.body, @project.name
    assert_includes response.body, @customer.name

    post accept_project_share_invitation_path(share.invitation_token), params: { organization_id: @customer.id }
    assert_redirected_to shared_project_path(@project)
    assert share.reload.accepted?
    assert_equal @customer, share.organization
  end

  test "an invitation cannot be accepted into the owner's organization" do
    share = invite(@owner_admin.email)
    sign_in @owner_admin

    post accept_project_share_invitation_path(share.invitation_token), params: { organization_id: @project.organization.id }
    assert share.reload.pending?
  end

  test "an invitee who administers only the owning organization is told they have nowhere else to put it" do
    invitee = User.create!(email: "both@example.com", first_name: "Bo", last_name: "Both", password: "password", invitation_accepted_at: Time.current)
    AccessInfo.create!(user: invitee, organization: @project.organization, role: :organization_admin, active: true)
    AccessInfo.create!(user: invitee, organization: @customer, role: :organization_user)
    share = invite(invitee.email)
    sign_in invitee

    get project_share_invitation_path(share.invitation_token)
    assert_includes response.body, I18n.t("project_shares.invitation.no_other_organization")
    assert_not_includes response.body, accept_project_share_invitation_path(share.invitation_token)
  end

  test "an invitation sent to someone else cannot be opened or accepted" do
    share = invite
    sign_in users(:customer_member)

    get project_share_invitation_path(share.invitation_token)
    assert_redirected_to root_path
    post accept_project_share_invitation_path(share.invitation_token), params: { organization_id: @customer.id }
    assert share.reload.pending?
  end

  test "declining leaves nothing shared" do
    share = invite
    sign_in @customer_admin

    post reject_project_share_invitation_path(share.invitation_token)
    assert share.reload.rejected?
    assert_empty Project.shared_with(@customer)
  end

  test "signing in from an invitation link returns to the invitation" do
    share = invite

    get project_share_invitation_path(share.invitation_token)
    assert_redirected_to new_user_session_path
    post user_session_path, params: { user: { email: @customer_admin.email, password: "password" } }
    assert_redirected_to project_share_invitation_path(share.invitation_token)
  end

  test "the customer's admin reads hours, consultants, notes and cost, in the owner's currency" do
    accepted_share
    sign_in @customer_admin

    get shared_projects_path(filter: @period)
    assert_response :success
    assert_includes response.body, @project.organization.name
    assert_includes response.body, @project.name

    get shared_project_path(@project, filter: @period)
    assert_response :success
    assert_includes response.body, users(:joe).name
    assert_includes response.body, time_regs(:time_reg_1).notes
    assert_includes response.body, @project.organization.currency
    assert_not_includes response.body, @customer.currency
  end

  test "the CSV export has names but no email addresses" do
    accepted_share
    sign_in @customer_admin

    get export_shared_project_path(@project, filter: @period)
    assert_response :success
    assert_equal "text/csv", response.media_type
    rows = CSV.parse(response.body, headers: true)
    assert_equal %w[date project task consultant notes minutes hours amount currency], rows.headers
    assert_includes rows.map { |row| row["consultant"] }, users(:joe).name
    assert_not_includes response.body, users(:joe).email
  end

  test "the shared projects menu appears for the customer's admin only once something is shared" do
    sign_in @customer_admin
    get reports_path
    assert_not_includes response.body, shared_projects_path

    accepted_share # signs the owner in and out
    sign_in @customer_admin
    get reports_path
    assert_includes response.body, shared_projects_path
  end

  test "the customer's other members cannot reach shared projects" do
    accepted_share
    sign_in users(:customer_member)

    get shared_projects_path
    assert_redirected_to root_path
    get shared_project_path(@project)
    assert_redirected_to shared_projects_path
    follow_redirect!
    assert_redirected_to root_path
  end

  test "the customer cannot reach the project through the owner's pages" do
    accepted_share
    sign_in @customer_admin

    get workspace_project_path(@project)
    assert_redirected_to root_path

    time_reg = time_regs(:time_reg_1)
    patch time_reg_path(time_reg), params: { time_reg: { notes: "Hijacked" } }
    assert_not_equal "Hijacked", time_reg.reload.notes

    get export_time_regs_path(project_id: @project.id)
    assert_not_equal "text/csv", response.media_type
  end

  test "an unshared project is not found on the shared pages" do
    sign_in @customer_admin
    get shared_project_path(projects(:project_2))
    assert_redirected_to shared_projects_path
  end

  test "the owner revokes and the customer loses access" do
    share = accepted_share
    sign_in @owner_admin
    delete workspace_project_share_path(@project, share)
    assert share.reload.revoked?

    sign_in @customer_admin
    get shared_project_path(@project)
    assert_redirected_to shared_projects_path
  end

  test "the customer can remove a shared project themselves" do
    share = accepted_share
    sign_in @customer_admin

    delete shared_project_path(@project)
    assert_redirected_to shared_projects_path
    assert share.reload.revoked?
  end
end
