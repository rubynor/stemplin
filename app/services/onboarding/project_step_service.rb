module Onboarding
  class ProjectStepService
    attr_reader :step_data

    def initialize(user, session, params)
      @user = user
      @session = session
      @params = params
      @step_data = {}
    end

    def execute
      @project = Project.new(project_params.merge(
        client_id: @session[:client_id],
        rate: 0,
        onboarding: true
      ))
      
      if @project.save
        @step_data = { project: @project }
        true
      else
        @step_data = { project: @project }
        false
      end
    end

    private

    def project_params
      @params.require(:project).permit(:name)
    end
  end
end 