require "test_helper"

class ReportsControllerTest < ActionController::TestCase
  setup do
    @user = users(:joe)
    sign_in @user
    get :index
  end

  test "should get index" do
    assert_response :success
    assert_not_nil assigns(:filter)
  end

  test "should have default start_date and end_date" do
    assert_equal Date.today.beginning_of_month, assigns(:filter).start_date
    assert_equal Date.today.end_of_month, assigns(:filter).end_date
    assert_equal true, assigns(:filter).default_period?
    assert_equal true, assigns(:filter).valid_time_frame?
    assert_equal false, assigns(:filter).is_custom_time_frame?
  end

  test "should have the default tab/category selected" do
    assert_equal Reports::Filter::CLIENTS, assigns(:filter).category
    assert_equal Reports::Filter::CLIENTS, assigns(:filter).active_tab
  end

  test "should have the default time_frame selected" do
    assert_equal Reports::Filter::MONTH, assigns(:filter).time_frame
  end

  test "should have attributes for filter set to nil by default" do
    assert_nil assigns(:filter).client_ids
    assert_nil assigns(:filter).project_ids
    assert_nil assigns(:filter).task_ids
    assert_nil assigns(:filter).user_ids
  end

  test "should be able to toggle next_period in this case by default next month" do
    end_date = Date.today.end_of_month
    new_date = end_date + 1.month
    next_period_range = { start_date: new_date.beginning_of_month, end_date: new_date.end_of_month }

    assert_equal next_period_range, assigns(:filter).next_period
  end

  test "should be able to toggle previous_period in this case by default previous month" do
    end_date = Date.today.end_of_month
    new_date = end_date - 1.month
    next_period_range = { start_date: new_date.beginning_of_month, end_date: new_date.end_of_month }

    assert_equal next_period_range, assigns(:filter).previous_period
  end

  test "should be able to select a week time_frame" do
    get :index, params: { filter: { time_frame: Reports::Filter::WEEK } }
    assert_equal Reports::Filter::WEEK, assigns(:filter).time_frame
    assert_equal Date.today.beginning_of_week, assigns(:filter).start_date
    assert_equal Date.today.end_of_week, assigns(:filter).end_date
    assert_equal false, assigns(:filter).is_custom_time_frame?
  end

  test "should be able to select a year time_frame" do
    get :index, params: { filter: { time_frame: Reports::Filter::YEAR } }
    assert_equal Reports::Filter::YEAR, assigns(:filter).time_frame
    assert_equal Date.today.beginning_of_year, assigns(:filter).start_date
    assert_equal Date.today.end_of_year, assigns(:filter).end_date
    assert_equal false, assigns(:filter).is_custom_time_frame?
  end

  test "should be able to select a custom time_frame" do
    start_date = Date.today.beginning_of_week - 1.week
    end_date = Date.today.end_of_week + 21.days
    get :index, params: { filter: { time_frame: Reports::Filter::CUSTOM, start_date: start_date, end_date: end_date } }
    assert_equal Reports::Filter::CUSTOM, assigns(:filter).time_frame
    assert_equal start_date, assigns(:filter).start_date
    assert_equal end_date, assigns(:filter).end_date
    assert_equal true, assigns(:filter).is_custom_time_frame?
  end

  test "should be able to select a client" do
    client = clients(:e_corp)
    selected_client_available_tabs = [ { value: "projects", label: "Projects" }, { value: "tasks", label: "Tasks" }, { value: "users", label: "Team members" } ]

    get :index, params: { filter: { client_ids: [ client.id ] } }
    assert_equal client.id, assigns(:filter).client_ids.first.to_i
    assert_equal client.name, assigns(:filter).selected_elements_names[Reports::Filter::CLIENTS].first
    assert_equal selected_client_available_tabs, assigns(:filter).tabs
  end

  test "should be able to select a project" do
    project = projects(:project_1)
    selected_project_available_tabs = [ { value: "tasks", label: "Tasks" }, { value: "users", label: "Team members" } ]

    get :index, params: { filter: { project_ids: [ project.id ] } }
    assert_equal project.id, assigns(:filter).project_ids.first.to_i
    assert_equal project.name, assigns(:filter).selected_elements_names[Reports::Filter::PROJECTS].first
    assert_equal selected_project_available_tabs, assigns(:filter).tabs
  end

  test "should be able to select a task" do
    task = tasks(:debug)
    selected_task_available_tabs = [ { value: "projects", label: "Projects" }, { value: "users", label: "Team members" } ]

    get :index, params: { filter: { task_ids: [ task.id ] } }
    assert_equal task.id, assigns(:filter).task_ids.first.to_i
    assert_equal task.name, assigns(:filter).selected_elements_names[Reports::Filter::TASKS].first
    assert_equal selected_task_available_tabs, assigns(:filter).tabs
  end

  test "should be able to select a user" do
    user = users(:joe)
    selected_user_available_tabs = [ { value: "projects", label: "Projects" }, { value: "tasks", label: "Tasks" } ]

    get :index, params: { filter: { user_ids: [ user.id ] } }
    assert_equal user.id, assigns(:filter).user_ids.first.to_i
    assert_equal user.name, assigns(:filter).selected_elements_names[Reports::Filter::USERS].first
    assert_equal selected_user_available_tabs, assigns(:filter).tabs
  end

  test "should get detailed" do
    get :detailed
    assert_response :success
    assert_not_nil assigns(:filter)
  end
end
