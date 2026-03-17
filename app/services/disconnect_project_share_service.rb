class DisconnectProjectShareService
  attr_reader :project_share

  def initialize(project_share:)
    @project_share = project_share
  end

  def call
    ActiveRecord::Base.transaction do
      destroy_guest_project_accesses
      cancel_pending_invitations
      project_share.destroy!
    end
  end

  private

  def project
    project_share.project
  end

  def guest_organization
    project_share.organization
  end

  def guest_access_infos
    guest_organization.access_infos
  end

  def destroy_guest_project_accesses
    ProjectAccess.where(
      project: project,
      access_info: guest_access_infos
    ).destroy_all
  end

  def cancel_pending_invitations
    guest_emails = guest_organization.users.pluck(:email)
    return if guest_emails.empty?

    ProjectInvitation
      .pending
      .where(project: project, invited_email: guest_emails)
      .find_each(&:reject!)
  end
end
