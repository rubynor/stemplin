require "simplecov"
require "simplecov-lcov"

SimpleCov::Formatter::LcovFormatter.config do |c|
  c.output_directory = "coverage"
  c.lcov_file_name = "lcov.info"
end

SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter

SimpleCov.start "rails" do
  add_filter "/bin/"
  add_filter "/db/"
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/app/javascript/"
  add_filter "/app/views/components/"

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
  fixtures :all
end

class ActionController::TestCase
  fixtures :all
  include Devise::Test::ControllerHelpers
  include ActionPolicy::TestHelper
end
