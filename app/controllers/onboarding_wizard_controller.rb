class OnboardingWizardController < ApplicationController
  include Wicked::Wizard
  skip_verify_authorized

  steps :organization, :setup_choice, :client, :project, :tasks, :finish

  # Setting up clients, projects and tasks is for the organization's admins:
  # the wizard must not be a way around the workspace policies.
  SETUP_STEPS = %i[client project tasks].freeze

  before_action :authenticate_user!
  before_action :require_organization_admin, if: -> { SETUP_STEPS.include?(step) }
  layout "devise"

  def show
    if step != :organization && current_user.organizations.empty?
      redirect_to wizard_path(:organization)
      return
    end

    case step
    when :organization
      @organization = Organization.new
    when :setup_choice
      # No-op, just render the choice view
    when :client
      @client = Client.new(organization: current_user.current_organization)
    when :project
      @client = wizard_client
      @project = Project.new(client: @client, rate: 0)
    when :tasks
      @project = wizard_project
      @task = Task.new(organization: current_user.current_organization)
    end
    render_wizard
  end

  def update
    case step
    when :organization
      @organization = Organization.new(organization_params)
      @organization.save!
      AccessInfo.create!(user: current_user, organization: @organization, role: AccessInfo.roles[:organization_admin])
      redirect_to next_wizard_path
    when :setup_choice
      # No-op, just go to next step
      redirect_to next_wizard_path
    when :client
      @client = Client.new(client_params.merge(organization: current_user.current_organization))
      @client.save!
      session[:client_id] = @client.id
      redirect_to next_wizard_path
    when :project
      @project = Project.new(project_params.merge(client: wizard_client, onboarding: true))
      @project.save!
      session[:project_id] = @project.id
      access_info = current_user.access_info(@project.organization)
      ProjectAccess.create!(project: @project, access_info: access_info)
      redirect_to next_wizard_path
    when :tasks
      @task = Task.new(task_params.merge(organization: current_user.current_organization))
      @task.save!
      AssignedTask.create!(project: wizard_project, task: @task)
      redirect_to next_wizard_path
    else
      redirect_to stored_location_for(:user) || root_path
    end
  end

  def skip
    redirect_to stored_location_for(:user) || root_path
  end

  private

  def require_organization_admin
    return redirect_to(wizard_path(:organization)) if current_user.organizations.empty?

    redirect_to root_path unless current_user.organization_admin?
  end

  # The client and project made earlier in the wizard, looked up within the
  # current organization.
  def wizard_client
    current_user.current_organization.clients.find(session[:client_id])
  end

  def wizard_project
    Project.owned_by(current_user.current_organization).find(session[:project_id])
  end

  def organization_params
    params.require(:organization).permit(:name, :currency)
  end

  def client_params
    params.require(:client).permit(:name, :description)
  end

  def project_params
    params.require(:project).permit(:name, :description, :billable, :rate_currency)
  end

  def task_params
    params.require(:task).permit(:name)
  end
end
