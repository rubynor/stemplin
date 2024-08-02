class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :check_if_user_has_organization
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

  private

  def check_if_user_has_organization
    redirect_to root_path if current_user.organizations.any?
  end

  def onboarding_params
    params.require(:organization).permit(:name, :currency)
  end
end
