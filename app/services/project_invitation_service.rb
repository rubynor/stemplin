class ProjectInvitationService
  include ActionPolicy::Behaviour
  include Rails.application.routes.url_helpers

  attr_reader :project, :email, :inviting_user

  def initialize(project:, email:, inviting_user:)
    @project = project
    @email = email.strip.downcase
    @inviting_user = inviting_user
  end

  def call
    begin
      return false unless can_invite?
      return false if same_organization?

      ActiveRecord::Base.transaction do
        create_project_invitation
        send_invitation_email
      end

      true
    rescue => e
      Rails.logger.error "Project invitation failed: #{e.message}"
      false
    end
  end

  def self.accept_invitation(invitation_token, organization)
    begin
      invitation = ProjectInvitation.find_by(invitation_token: invitation_token)
      return false unless invitation
      return false unless invitation.can_be_accepted?

      invitation.accept!(organization)
      true
    rescue => e
      Rails.logger.error "Project invitation acceptance failed: #{e.message}"
      false
    end
  end

  def self.reject_invitation(invitation_token)
    begin
      invitation = ProjectInvitation.find_by(invitation_token: invitation_token)
      return false unless invitation
      return false unless invitation.can_be_accepted?

      invitation.reject!
      true
    rescue => e
      Rails.logger.error "Project invitation rejection failed: #{e.message}"
      false
    end
  end

  private

  def can_invite?
    authorize! @project, to: :invite_external_user?
    true
  rescue ActionPolicy::Unauthorized
    false
  end

  def same_organization?
    invited_user = User.find_by(email: @email)
    return false unless invited_user&.organizations&.include?(@project.organization)
    true
  end

  def create_project_invitation
    @project_invitation = ProjectInvitation.create!(
      project: @project,
      invited_email: @email,
      invited_by: @inviting_user,
      invited_at: Time.current
    )
  end

  def send_invitation_email
    UserMailer.project_invitation_email(
      project_invitation: @project_invitation,
      inviting_user: @inviting_user,
      project: @project
    ).deliver_later
  end

  def implicit_authorization_target
    @project
  end

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end
end
