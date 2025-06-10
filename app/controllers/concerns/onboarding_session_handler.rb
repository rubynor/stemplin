module OnboardingSessionHandler
  extend ActiveSupport::Concern

  private

  def store_step_data(data)
    case step
    when :client
      session[:client_id] = data[:client].id
    when :project
      session[:project_id] = data[:project].id
    end
  end
end 