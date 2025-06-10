module Onboarding
  class TaskStepService
    attr_reader :step_data

    def initialize(user, session, params)
      @user = user
      @session = session
      @params = params
      @step_data = {}
    end

    def execute
      @task = Task.new(task_params.merge(organization: @user.current_organization))
      
      if @task.save
        AssignedTask.create!(project_id: @session[:project_id], task: @task)
        @step_data = { task: @task }
        true
      else
        @step_data = { task: @task }
        false
      end
    end

    private

    def task_params
      @params.require(:task).permit(:name)
    end
  end
end 