class Users::PasswordsController < Devise::PasswordsController
  invisible_captcha prepend: true, only: [ :create ], on_spam: :handle_spam, on_timestamp_spam: :handle_spam, scope: :user

  private

  def handle_spam
    flash[:notice] = t("devise.passwords.send_instructions")
    redirect_to new_user_session_path
  end
end
