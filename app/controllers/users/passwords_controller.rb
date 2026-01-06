class Users::PasswordsController < Devise::PasswordsController
  include Rails.application.routes.url_helpers

  invisible_captcha prepend: true, only: [ :create ], on_spam: :handle_spam, on_timestamp_spam: :handle_spam, scope: :user

  def create
    user = User.find_by(email: resource_params[:email])
    if user&.pending_invitation?
      resend_invitation(user)
      flash[:notice] = t("devise.passwords.send_paranoid_instructions_check_spam")
      redirect_to new_user_session_path
    else
      super
    end
  end

  private

  def handle_spam
    flash[:notice] = t("devise.passwords.send_instructions")
    redirect_to new_user_session_path
  end

  def resend_invitation(user)
    organization = user.organizations.first
    UserMailer.welcome_email(
      user: user,
      organization_name: organization&.name || "Stemplin",
      url: accept_user_invitation_url(invitation_token: user.raw_invitation_token, **default_url_options)
    ).deliver_later
  end

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end
end
