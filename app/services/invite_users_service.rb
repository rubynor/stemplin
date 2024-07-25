class InviteUsersService
  include ActionPolicy::Behaviour
  include Rails.application.routes.url_helpers

  attr_reader :invite_users_hash, :current_user

  def initialize(invite_users_hash, current_user)
    @invite_users_hash = invite_users_hash
    @current_user = current_user
    @mail_new_users = []
    @mail_existing_users = []
  end

  # Synchronously invites users and sends welcome emails. TODO: Do this asynchronously if it becomes a performance bottleneck.
  def call
    begin
      raise StandardError unless @invite_users_hash.values.map(&:valid?).all?

      ActiveRecord::Base.transaction do
        process_invitations
      end

      mail_users
      true
    rescue => e
      Rails.logger.error "User invitation failed: #{e.message}"
      false
    end
  end


  private

  def process_invitations
    @invite_users_hash.values.each do |invite_user_form|
      user = find_or_create_user invite_user_form
      access_info = user.update_or_create_access_info invite_user_form.role, @current_user.current_organization
      access_info.update_project_accesses invite_user_form.project_ids
    end
  end

  def find_or_create_user(invite_user_form)
    user = User.find_by(email: invite_user_form.email)
    if user.nil? || user.pending_invitation?
      user = create_user invite_user_form.email
      @mail_new_users << user
    elsif user.access_infos.find_by(organization: @current_user.current_organization).nil?
      @mail_existing_users << user
    end
    user
  end

  def create_user(email)
    User.invite!({ email: email }, @current_user) do |u|
      u.skip_invitation = true
    end
  end

  def mail_users
    @mail_new_users.each do |user|
      UserMailer.welcome_email(
        user: user,
        organization_name: @current_user.current_organization.name,
        url: accept_user_invitation_url(invitation_token: user.raw_invitation_token, **default_url_options)
      ).deliver_later
    end
    @mail_existing_users.each do |user|
      UserMailer.welcome_email(
        user: user,
        organization_name: @current_user.current_organization.name,
        url: new_user_session_url(**default_url_options)
      ).deliver_later
    end
  end

  def implicit_authorization_target
    User
  end

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end
end
