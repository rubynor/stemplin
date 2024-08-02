require "simplecov"
SimpleCov.start "rails" do
  add_filter "/bin/"
  add_filter "/db/"
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/app/javascript/"
  add_filter "/app/views/components/"

  # Groups not covered by default
  add_group "Policies", "app/policies"
  add_group "Presenters", "app/presenters"
  add_group "Services", "app/services"
  add_group "Components", "app/views/components"
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "rails-controller-testing"
require "action_policy/test_helper"
require "sidekiq/testing"

Sidekiq::Testing.fake!

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers

  # Parallel tests disabled. Can be enables, but requires some configuration with simplecov
  # parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end


class ActionController::TestCase
  # Parallel tests disabled. Can be enables, but requires some configuration with simplecov
  # parallelize(workers: :number_of_processors)
  fixtures :all
  include Devise::Test::ControllerHelpers
  include ActionPolicy::TestHelper
end
