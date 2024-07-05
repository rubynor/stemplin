class UserMailer < ApplicationMailer
  def welcome_email(to:)
    send_mail(
      to: to,
      # TODO: get locale from current_user
      template_id: Stemplin.config.emails.templates[:user][:welcome][I18n.locale][:template_id],
      personalization_data: {
        # TODO: should be translated
        subject: "Welcome to Stemplin",
        message: "Hello world",
        link: "https://www.stemplin.com"
      }
    )
  end
end
