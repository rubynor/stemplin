class OnboardingWizardController < ApplicationController
  include Wicked::Wizard
  include OnboardingSessionHandler
  skip_verify_authorized

  steps :client, :project, :tasks, :finish

  before_action :authenticate_user!
  layout "devise"

  def show
    @step_data = step_data
    render_wizard
  end

  def update
    service = step_service.new(current_user, session, params)
    
    if service.execute
      store_step_data(service.step_data)
      redirect_to next_wizard_path
    else
      @step_data = service.step_data
      render_wizard
    end
  end

  def skip
    redirect_to root_path
  end

  private

  def step_data
    case step
    when :client
      { client: Client.new(organization: current_user.current_organization) }
    when :project
      { project: Project.new(client_id: session[:client_id], rate: 0) }
    when :tasks
      { task: Task.new(organization: current_user.current_organization) }
    end
  end

  def step_service
    case step
    when :client
      Onboarding::ClientStepService
    when :project
      Onboarding::ProjectStepService
    when :tasks
      Onboarding::TaskStepService
    end
  end
end 