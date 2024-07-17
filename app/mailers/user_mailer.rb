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

  def reset_password_instructions(record, token, opts = {})
    Rails.logger.info "----> record #{record.inspect}"
    Rails.logger.info "----> token #{token}"
    Rails.logger.info "----> opts #{opts.inspect}"
    super
  end
end
