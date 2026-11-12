# Slows down password guessing and mail flooding on the sign-in, sign-up and
# password reset forms: a handful of attempts per address, then a short wait.
module AuthRateLimiting
  extend ActiveSupport::Concern

  included do
    rate_limit to: 10, within: 3.minutes, only: :create, with: -> { too_many_attempts }
  end

  private

  def too_many_attempts
    redirect_to new_user_session_path, alert: t("alert.too_many_attempts")
  end
end
