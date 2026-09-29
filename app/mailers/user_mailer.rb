class UserMailer < Devise::Mailer
  def welcome_email(user:, organization_name:, url:)
    mail(
      to: user.email,
      sendgrid_template: Stemplin.config.emails.templates[:user][:welcome][I18n.locale][:template_id],
      content: {
        organization_name: organization_name,
        user_name: user.name,
        url: url
      }
    )
  end

  # One email for shares sent together; the link opens all of them, since they are answered together.
  def project_share_invitation_email(project_shares:)
    share = project_shares.first
    @projects = project_shares.map(&:project)
    @clients = @projects.map(&:client).uniq.map(&:name).to_sentence
    @owner = share.project.organization
    @inviting_user = share.invited_by
    @url = project_share_invitation_url(share.invitation_token)
    locale = User.find_by(email: share.invited_email)&.locale || @inviting_user.locale

    I18n.with_locale(locale) do
      subject = if @projects.one?
        t("project_shares.email.subject", organization: @owner.name, project: @projects.first.name, client: @clients)
      else
        t("project_shares.email.subject_many", organization: @owner.name, count: @projects.size, client: @clients)
      end
      mail(to: share.invited_email, subject: subject)
    end
  end

  # @Note: This overrides `reset_password_instructions` from Devise::Mailer to send a sendgrid template
  # this implementations sends over a url with the `reset_password_token`
  # I think this is something Sendgrid should be handling well, but if it poses security concerns
  # let's just remove this method and use a mailer view
  def reset_password_instructions(record, token, opts = nil)
    mail(
      to: record.email,
      sendgrid_template: Stemplin.config.emails.templates[:user][:password_reset][I18n.locale][:template_id],
      content: {
        subject: "Reset password",
        user_name: record.name,
        url: edit_user_password_url(record, reset_password_token: token)
      }
    )
  end
end
