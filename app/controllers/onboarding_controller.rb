class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :check_if_user_has_organization, only: %i[new create]
  skip_verify_authorized

  layout "devise"

  def new
    @organization = Organization.new
    @user = current_user
  end

  def create
    @organization = Organization.new(onboarding_params)

    ActiveRecord::Base.transaction do
      @organization.save!
      AccessInfo.create!(user: current_user, organization: @organization, role: AccessInfo.roles[:organization_admin])
    end

    redirect_to root_path, notice: "Organization created successfully"
  rescue => e
    render turbo_stream: turbo_stream.replace(:onboarding_form, partial: "onboarding/form", locals: { organization: @organization })
  end

  def edit_password
    @user = current_user
  end

  # @Note: This method here below is not production grade code.
  # This is just a workaround to ensure a new organization_user can update their generated password
  # TODO: Remove this implementation on introducing a proper invitation
  def update_password
    @user = current_user

    if @user.valid_password?(password_params[:current_password])
      begin
        @user.update!(password_params.except(:current_password).merge(is_verified: true))
        bypass_sign_in(@user)
        redirect_to root_path, notice: "Password updated successfully"
      rescue ActiveRecord::RecordInvalid => e
        render turbo_stream: turbo_stream.replace(:onboarding_edit_password, partial: "onboarding/edit_password_form", locals: { user: @user })
      end
    else
      @user.errors.add(:current_password, "is invalid")
      render turbo_stream: turbo_stream.replace(:onboarding_edit_password, partial: "onboarding/edit_password_form", locals: { user: @user })
    end
  end

  def skip_and_verify_account
    current_user.update!(is_verified: true)
    redirect_to root_path, notice: "Account verified successfully"
  end

  private

  def check_if_user_has_organization
    redirect_to root_path if current_user.organizations.any?
  end

  def onboarding_params
    params.require(:organization).permit(:name)
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation, :current_password)
  end
end
