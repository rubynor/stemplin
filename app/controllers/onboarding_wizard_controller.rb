class OnboardingWizardController < ApplicationController
  include Wicked::Wizard
  skip_verify_authorized

  steps :organization, :setup_choice, :client, :project, :tasks, :finish

  before_action :authenticate_user!
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
      @client = Client.find(session[:client_id])
      @project = Project.new(client_id: session[:client_id], rate: 0)
    when :tasks
      @project = Project.find(session[:project_id])
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
      @project = Project.new(project_params.merge(client_id: session[:client_id], onboarding: true))
      @project.save!
      session[:project_id] = @project.id
      access_info = current_user.access_info(@project.organization)
      ProjectAccess.create!(project: @project, access_info: access_info)
      redirect_to next_wizard_path
    when :tasks
      @task = Task.new(task_params.merge(organization: current_user.current_organization))
      @task.save!
      AssignedTask.create!(project_id: session[:project_id], task: @task)
      redirect_to next_wizard_path
    else
      redirect_to root_path
    end
  end

  def skip
    redirect_to root_path
  end

  private

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
