require "test_helper"
require_relative "base_test"

class Api::V1::TimeRegsControllerTest < Api::V1::BaseTest
  setup do
    @user = users(:joe)
    @time_reg = time_regs(:time_reg_1)
    @assigned_task = projects(:project_1).assigned_tasks.first
  end

  test "index returns paginated time regs" do
    get api_v1_time_regs_path, headers: api_headers(@user)
    assert_response :success

    assert json_response.key?("time_regs")
    assert json_response.key?("pagination")
    assert_kind_of Array, json_response["time_regs"]
  end

  test "index filters by date" do
    get api_v1_time_regs_path(date: Date.today.to_s), headers: api_headers(@user)
    assert_response :success

    json_response["time_regs"].each do |tr|
      assert_equal Date.today.to_s, tr["date_worked"]
    end
  end

  test "show returns time reg details" do
    get api_v1_time_reg_path(@time_reg), headers: api_headers(@user)
    assert_response :success
    assert_equal @time_reg.id, json_response["id"]
    assert_equal @time_reg.notes, json_response["notes"]
  end

  test "create time reg" do
    assert_difference("TimeReg.count") do
      post api_v1_time_regs_path,
        params: { time_reg: { date_worked: Date.today, minutes: 60, assigned_task_id: @assigned_task.id } },
        headers: api_headers(@user)
    end
    assert_response :created
  end

  test "update time reg" do
    patch api_v1_time_reg_path(@time_reg),
      params: { time_reg: { notes: "Updated via API" } },
      headers: api_headers(@user)
    assert_response :success
    assert_equal "Updated via API", json_response["notes"]
  end

  test "destroy time reg" do
    delete api_v1_time_reg_path(@time_reg), headers: api_headers(@user)
    assert_response :no_content
    assert_raises(ActiveRecord::RecordNotFound) { TimeReg.find(@time_reg.id) }
  end

  test "toggle active starts timer" do
    assert_not @time_reg.active?
    patch toggle_active_api_v1_time_reg_path(@time_reg), headers: api_headers(@user)
    assert_response :success
    assert json_response["active"]
  end

  test "cannot access another user time reg" do
    other_user_time_reg = time_regs(:time_reg_2)
    get api_v1_time_reg_path(other_user_time_reg), headers: api_headers(@user)
    assert_response :not_found
  end
end
