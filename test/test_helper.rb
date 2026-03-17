require "simplecov"
require "simplecov-lcov"

SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.single_report_path = "coverage/lcov/app.lcov"
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::LcovFormatter
])

SimpleCov.start "rails" do
  enable_coverage :branch
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
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Switch a user's active organization context for cross-org testing
  def switch_org_context!(user, organization)
    user.access_infos.update_all(active: false)
    user.access_infos.find_by(organization: organization).update!(active: true)
  end
end


class ActionController::TestCase
  parallelize(workers: :number_of_processors)
  fixtures :all
  include Devise::Test::ControllerHelpers
  include ActionPolicy::TestHelper
end
