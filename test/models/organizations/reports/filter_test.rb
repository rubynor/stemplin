require "test_helper"

module Organizations
  module Reports
    class FilterTest < ActiveSupport::TestCase
      def setup
        @default_date = Date.today
        @client = clients(:google_xyz)
        @project = projects(:project_1)
        @task = tasks(:debug)
        @user = users(:joe)
        @filter_class = Organizations::Reports::Filter
      end

      def filter_with(params = {})
        @filter_class.new(params)
      end

      test "default time range when not set should be current date beginning_of_month and end_of_month" do
        filter = filter_with
        assert_equal @default_date.beginning_of_month, filter.start_date
        assert_equal @default_date.end_of_month, filter.end_date
      end

      test "default category should be CLIENTS" do
        filter = filter_with
        assert_equal @filter_class::CLIENTS, filter.category
      end

      test "default time_frame should be MONTH" do
        filter = filter_with
        assert_equal @filter_class::MONTH, filter.time_frame
      end

      test "#selected_element_names returns hash with names of the selected elements" do
        filter = filter_with(client_ids: [ @client.id ])
        assert_equal @client.name, filter.selected_elements_names[@filter_class::CLIENTS].first

        filter = filter_with(project_ids: [ @project.id ])
        assert_equal @project.name, filter.selected_elements_names[@filter_class::PROJECTS].first

        filter = filter_with(task_ids: [ @task.id ])
        assert_equal @task.name, filter.selected_elements_names[@filter_class::TASKS].first

        filter = filter_with(user_ids: [ @user.id ])
        assert_equal @user.name, filter.selected_elements_names[@filter_class::USERS].first
      end

      test "#next_period increments the period by 1 week when selected time_frame is week" do
        filter = filter_with(time_frame: @filter_class::WEEK)
        new_date = @default_date + 1.week
        new_week_range = { start_date: new_date.beginning_of_week, end_date: new_date.end_of_week }
        assert_equal new_week_range, filter.next_period
      end

      test "#next_period increments the period by 1 month when selected time_frame is month" do
        filter = filter_with(time_frame: @filter_class::MONTH)
        new_date = @default_date + 1.month
        new_month_range = { start_date: new_date.beginning_of_month, end_date: new_date.end_of_month }
        assert_equal new_month_range, filter.next_period
      end

      test "#next_period increments the period by 1 year when selected time_frame is year" do
        filter = filter_with(time_frame: @filter_class::YEAR)
        new_date = @default_date + 1.year
        new_year_range = { start_date: new_date.beginning_of_year, end_date: new_date.end_of_year }
        assert_equal new_year_range, filter.next_period
      end

      test "#previous_period decrements the period by 1 week when selected time_frame is week" do
        filter = filter_with(time_frame: @filter_class::WEEK)
        new_date = @default_date - 1.week
        new_week_range = { start_date: new_date.beginning_of_week, end_date: new_date.end_of_week }
        assert_equal new_week_range, filter.previous_period
      end

      test "#previous_period decrements the period by 1 month when selected time_frame is month" do
        filter = filter_with(time_frame: @filter_class::MONTH)
        new_date = @default_date - 1.month
        new_month_range = { start_date: new_date.beginning_of_month, end_date: new_date.end_of_month }
        assert_equal new_month_range, filter.previous_period
      end

      test "#previous_period decrements the period by 1 year when selected time_frame is year" do
        filter = filter_with(time_frame: @filter_class::YEAR)
        new_date = @default_date - 1.year
        new_year_range = { start_date: new_date.beginning_of_year, end_date: new_date.end_of_year }
        assert_equal new_year_range, filter.previous_period
      end

      test "#current_time_range returns the current selected time range" do
        filter = filter_with
        assert_equal({ start_date: filter.start_date, end_date: filter.end_date }, filter.current_time_range)
      end

      test "#default_period? returns true when the selected time_frame is the default period" do
        filter = filter_with(start_date: @default_date.beginning_of_month, end_date: @default_date.end_of_month)
        assert filter.default_period?

        filter = filter_with(start_date: @default_date.beginning_of_week, end_date: @default_date.end_of_week, time_frame: @filter_class::WEEK)
        assert filter.default_period?

        filter = filter_with(start_date: @default_date.beginning_of_year, end_date: @default_date.end_of_year, time_frame: @filter_class::YEAR)
        assert filter.default_period?
      end

      test "#default_period? returns false when the selected time_frame is not the default period" do
        filter = filter_with(start_date: @default_date.beginning_of_week + 1.day, end_date: @default_date.end_of_week, time_frame: @filter_class::MONTH)
        assert_not filter.default_period?

        filter = filter_with(start_date: @default_date.beginning_of_month + 1.day, end_date: @default_date.end_of_month, time_frame: @filter_class::YEAR)
        assert_not filter.default_period?

        filter = filter_with(start_date: @default_date.beginning_of_year + 1.day, end_date: @default_date.end_of_year, time_frame: @filter_class::WEEK)
        assert_not filter.default_period?
      end

      test "#valid_time_frame? returns true when the selected time_frame is a valid period range i.e (a week, a month or a year)" do
        filter = filter_with(start_date: @default_date.beginning_of_month, end_date: @default_date.end_of_month)
        assert filter.valid_time_frame?

        filter = filter_with(start_date: @default_date.beginning_of_week, end_date: @default_date.end_of_week, time_frame: @filter_class::WEEK)
        assert filter.valid_time_frame?

        filter = filter_with(start_date: @default_date.beginning_of_year, end_date: @default_date.end_of_year, time_frame: @filter_class::YEAR)
        assert filter.valid_time_frame?
      end

      test "#valid_time_frame? returns false when the selected time_frame is not a valid period range i.e (a week, a month or a year)" do
        filter = filter_with(start_date: @default_date.beginning_of_week + 1.day, end_date: @default_date.end_of_week + 5.day, time_frame: @filter_class::WEEK)
        assert_not filter.valid_time_frame?
      end

      test "#tabs should generate the right tabs for the selected category or expanded row category" do
        filter = filter_with
        assert_equal filter.generate_tabs(*@filter_class::CATEGORIES), filter.tabs

        filter = filter_with(client_ids: [ @client.id ])
        assert_equal filter.generate_tabs(*@filter_class::CLIENT_TABS), filter.tabs

        filter = filter_with(project_ids: [ @project.id ])
        assert_equal filter.generate_tabs(*@filter_class::PROJECT_TABS), filter.tabs

        filter = filter_with(task_ids: [ @task.id ])
        assert_equal filter.generate_tabs(*@filter_class::TASK_TABS), filter.tabs

        filter = filter_with(user_ids: [ @user.id ])
        assert_equal filter.generate_tabs(*@filter_class::USER_TABS), filter.tabs
      end

      test "#active_tab returns the active tab for the selected category" do
        filter = filter_with
        assert_equal @filter_class::CLIENTS, filter.active_tab

        filter = filter_with(category: @filter_class::CLIENTS)
        assert_equal @filter_class::CLIENTS, filter.active_tab

        filter = filter_with(category: @filter_class::PROJECTS)
        assert_equal @filter_class::PROJECTS, filter.active_tab

        filter = filter_with(category: @filter_class::TASKS)
        assert_equal @filter_class::TASKS, filter.active_tab

        filter = filter_with(category: @filter_class::USERS)
        assert_equal @filter_class::USERS, filter.active_tab
      end
    end
  end
end
