require "test_helper"
require_relative "base_test"

class Api::V1::ReportsControllerTest < Api::V1::BaseTest
  setup do
    @user = users(:joe)
  end

  test "index returns report summary" do
    get api_v1_reports_path, headers: api_headers(@user)
    assert_response :success

    assert json_response.key?("total_minutes")
    assert json_response.key?("total_entries")
    assert json_response.key?("by_project")
    assert json_response.key?("by_user")
  end

  test "index filters by date range" do
    get api_v1_reports_path(
      start_date: 1.week.ago.to_date.to_s,
      end_date: Date.today.to_s
    ), headers: api_headers(@user)
    assert_response :success
  end

  test "detailed returns entries grouped by date" do
    get detailed_api_v1_reports_path, headers: api_headers(@user)
    assert_response :success

    assert json_response.key?("total_minutes")
    assert json_response.key?("total_billable_minutes")
    assert json_response.key?("dates")

    first_date_group = json_response["dates"].first
    assert first_date_group.key?("date")
    assert first_date_group.key?("time_regs")

    entry = first_date_group["time_regs"].first
    assert entry.key?("id")
    assert entry.key?("minutes")
    assert entry.key?("user_name")
    assert entry.key?("client_name")
    assert entry.key?("project_name")
    assert entry.key?("task_name")
    assert entry.key?("rate")
    assert entry.key?("billed_amount")
  end

  test "detailed filters by date range" do
    get detailed_api_v1_reports_path(
      start_date: 1.week.ago.to_date.to_s,
      end_date: Date.today.to_s
    ), headers: api_headers(@user)
    assert_response :success
  end
end
