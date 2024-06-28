require "test_helper"
require_relative "shared_reports_tests"

module Organizations
  class ReportsControllerDetailedTest < ActionController::TestCase
    include SharedReportsTests

    def setup
      super
      @controller = ReportsController.new
      get :detailed
    end
  end
end
