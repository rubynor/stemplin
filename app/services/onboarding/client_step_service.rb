module Onboarding
  class ClientStepService
    attr_reader :step_data

    def initialize(user, session, params)
      @user = user
      @session = session
      @params = params
      @step_data = {}
    end

    def execute
      @client = Client.new(client_params.merge(organization: @user.current_organization))
      
      if @client.save
        @step_data = { client: @client }
        true
      else
        @step_data = { client: @client }
        false
      end
    end

    private

    def client_params
      @params.require(:client).permit(:name)
    end
  end
end 