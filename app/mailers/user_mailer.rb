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

  def project_invitation_email(project_invitation:, inviting_user:, project:)
    mail(
      to: project_invitation.invited_email,
      sendgrid_template: Stemplin.config.emails.templates[:user][:project_invitation][I18n.locale][:template_id],
      content: {
        inviting_user_name: inviting_user.name,
        inviting_organization_name: inviting_user.current_organization.name,
        project_name: project.name,
        client_name: project.client.name,
        accept_url: "", # accept_project_invitation_url(token: project_invitation.invitation_token),
        reject_url: "" # reject_project_invitation_url(token: project_invitation.invitation_token)
      }
    )
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
