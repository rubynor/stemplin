require "test_helper"
require_relative "shared_reports_tests"

module Organizations
  class ReportsControllerIndexTest < ActionController::TestCase
    include SharedReportsTests

    def setup
      super
      @controller = ReportsController.new
      get :index
    end

    test "should be able to select a month time_frame" do
      get :index, params: { filter: { time_frame: Organizations::Reports::Filter::MONTH } }
      assert_equal Organizations::Reports::Filter::MONTH, assigns(:filter).time_frame
      assert_equal Date.today.beginning_of_month, assigns(:filter).start_date
      assert_equal Date.today.end_of_month, assigns(:filter).end_date
      assert_equal false, assigns(:filter).is_custom_time_frame?
    end

    test "should be able to select a year time_frame" do
      get :index, params: { filter: { time_frame: Organizations::Reports::Filter::YEAR } }
      assert_equal Organizations::Reports::Filter::YEAR, assigns(:filter).time_frame
      assert_equal Date.today.beginning_of_year, assigns(:filter).start_date
      assert_equal Date.today.end_of_year, assigns(:filter).end_date
      assert_equal false, assigns(:filter).is_custom_time_frame?
    end

    test "should be able to select a custom time_frame" do
      start_date = Date.today.beginning_of_week - 1.week
      end_date = Date.today.end_of_week + 21.days
      get :index, params: { filter: { time_frame: Organizations::Reports::Filter::CUSTOM, start_date: start_date, end_date: end_date } }
      assert_equal Organizations::Reports::Filter::CUSTOM, assigns(:filter).time_frame
      assert_equal start_date, assigns(:filter).start_date
      assert_equal end_date, assigns(:filter).end_date
      assert_equal true, assigns(:filter).is_custom_time_frame?
    end

    test "should be able to select a client" do
      client = clients(:e_corp)
      selected_client_available_tabs = [ { value: "projects", label: "Projects" }, { value: "tasks", label: "Tasks" }, { value: "users", label: "Team members" } ]

      get :index, params: { filter: { client_id: client.id } }
      assert_equal client.id, assigns(:filter).client_id
      assert_equal client.name, assigns(:filter).selected_element_name
      assert_equal selected_client_available_tabs, assigns(:filter).tabs
    end

    test "should be able to select a project" do
      project = projects(:project_1)
      selected_project_available_tabs = [ { value: "tasks", label: "Tasks" }, { value: "users", label: "Team members" } ]

      get :index, params: { filter: { project_id: project.id } }
      assert_equal project.id, assigns(:filter).project_id
      assert_equal project.name, assigns(:filter).selected_element_name
      assert_equal selected_project_available_tabs, assigns(:filter).tabs
    end

    test "should be able to select a task" do
      task = tasks(:debug)
      selected_task_available_tabs = [ { value: "projects", label: "Projects" }, { value: "users", label: "Team members" } ]

      get :index, params: { filter: { task_id: task.id } }
      assert_equal task.id, assigns(:filter).task_id
      assert_equal task.name, assigns(:filter).selected_element_name
      assert_equal selected_task_available_tabs, assigns(:filter).tabs
    end

    test "should be able to select a user" do
      user = users(:joe)
      selected_user_available_tabs = [ { value: "projects", label: "Projects" }, { value: "tasks", label: "Tasks" } ]

      get :index, params: { filter: { user_id: user.id } }
      assert_equal user.id, assigns(:filter).user_id
      assert_equal user.name, assigns(:filter).selected_element_name
      assert_equal selected_user_available_tabs, assigns(:filter).tabs
    end
  end
end
