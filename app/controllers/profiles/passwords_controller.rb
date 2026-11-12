module Profiles
  # The password card on the profile page.
  class PasswordsController < AuthenticatedController
    def update
      @user = current_user
      @password_user = User.find(current_user.id)
      authorize! @password_user, to: :manage_profile?, with: UserPolicy

      if new_password_given? && @password_user.update_with_password(password_params)
        # Changing the password invalidates the session; keep the user signed in.
        bypass_sign_in(@password_user)
        redirect_to profile_path, notice: t("profile.password_updated")
      else
        render "profiles/show", status: :unprocessable_entity
      end
    end

    private

    def password_params
      params.require(:user).permit(:current_password, :password, :password_confirmation)
    end

    # Devise reads a blank new password as "keep the old one" and reports
    # success. Here the form exists only to change it, so blank is an error.
    def new_password_given?
      return true if password_params[:password].present?

      @password_user.errors.add(:password, :blank)
      false
    end
  end
end
