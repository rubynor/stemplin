require "test_helper"
require_relative "base_test"

class Api::V1::TimersControllerTest < Api::V1::BaseTest
  setup do
    @user = users(:joe)
    @time_reg = time_regs(:time_reg_1)
  end

  test "update starts timer" do
    assert_not @time_reg.active?
    patch api_v1_time_reg_timer_path(@time_reg), headers: api_headers(@user)
    assert_response :success
    assert json_response["active"]
  end

  test "update stops running timer" do
    @time_reg.update!(start_time: Time.now, date_worked: Date.today)
    assert @time_reg.active?

    patch api_v1_time_reg_timer_path(@time_reg), headers: api_headers(@user)
    assert_response :success
    assert_not json_response["active"]
  end

  test "cannot toggle another user timer" do
    other_time_reg = time_regs(:time_reg_2)
    patch api_v1_time_reg_timer_path(other_time_reg), headers: api_headers(@user)
    assert_response :not_found
  end
end
