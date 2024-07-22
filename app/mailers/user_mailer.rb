class UserMailer < ApplicationMailer
  def welcome_email(user:, organization_name:, url:)
    send_with_sendgrid(
      to: user.email,
      template_id: Stemplin.config.emails.templates[:user][:welcome][I18n.locale][:template_id],
      personalization_data: {
        organization_name: organization_name,
        user_name: user.name,
        url: url
      }
    )
  end
end
