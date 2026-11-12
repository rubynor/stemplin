# The signed-in user's own account page: personal details, password and API
# token, each saved by its own form.
class ProfilesController < AuthenticatedController
  before_action :set_user

  def show
    authorize! @user, to: :manage_profile?, with: UserPolicy
  end

  def update
    authorize! @user, to: :manage_profile?, with: UserPolicy
    @user.assign_attributes(profile_params)

    if @user.valid? && email_change_confirmed? && @user.save
      redirect_to profile_path, notice: t("profile.updated")
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  # A copy of current_user, so edits that get rejected don't show up in the
  # navigation bar of the page that reports them.
  def set_user
    @user = User.find(current_user.id)
  end

  def profile_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end

  # Whoever controls the email address can reset the password, so changing it
  # takes the current password. Runs after validation, which normalizes the
  # address: retyping it in another case is not a change.
  def email_change_confirmed?
    return true unless @user.email_changed?

    current_password = params.dig(:user, :current_password)
    return true if @user.valid_password?(current_password)

    @user.errors.add(:current_password, current_password.blank? ? :blank : :invalid)
    false
  end
end
