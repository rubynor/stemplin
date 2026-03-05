require "test_helper"
require_relative "base_test"

class Api::V1::TasksControllerTest < Api::V1::BaseTest
  setup do
    @user = users(:joe)
  end

  test "index returns scoped tasks" do
    get api_v1_tasks_path, headers: api_headers(@user)
    assert_response :success

    tasks = json_response
    assert_kind_of Array, tasks
    assert tasks.any? { |t| t["name"] == "Debug" }
  end

  test "show returns task details" do
    task = tasks(:debug)
    get api_v1_task_path(task), headers: api_headers(@user)
    assert_response :success
    assert_equal "Debug", json_response["name"]
  end
end
