require "test_helper"

class TimeReg::CopiesControllerTest < ActionController::TestCase
  setup do
    @user = users(:joe)
    @time_reg = time_regs(:time_reg_1)
    @target_date = Date.today + 3
    sign_in @user
  end

  test "should copy own time registration to a date" do
    assert_difference("TimeReg.count") do
      post :create, params: { time_reg_id: @time_reg.id, date: @target_date.to_s }
    end

    copy = TimeReg.order(:created_at).last
    assert_equal @target_date, copy.date_worked
    assert_equal @time_reg.assigned_task, copy.assigned_task
    assert_equal @time_reg.notes, copy.notes
    assert_equal @time_reg.minutes, copy.minutes
    assert_nil copy.start_time, "a copy must never inherit a running timer"
    assert_redirected_to time_regs_path(date: @target_date)
  end

  test "should copy to several dates at once" do
    dates = [ @target_date, @target_date + 1, @target_date + 2 ]
    assert_difference("TimeReg.count", 3) do
      post :create, params: { time_reg_id: @time_reg.id, dates: dates.map(&:to_s) }
    end
    assert_redirected_to time_regs_path(date: dates.last)
  end

  test "should default to today when no date is given" do
    assert_difference("TimeReg.count") do
      post :create, params: { time_reg_id: @time_reg.id }
    end
    assert_equal Date.today, TimeReg.order(:created_at).last.date_worked
  end

  test "should not copy a colleague's time registration" do
    colleagues = time_regs(:time_reg_1_organization_user_1)

    assert_no_difference("TimeReg.count") do
      post :create, params: { time_reg_id: colleagues.id, date: @target_date.to_s }
    end
    assert_redirected_to root_path
  end

  test "admin may copy a team member's time registration" do
    sign_in users(:organization_admin)

    assert_difference("TimeReg.count") do
      post :create, params: { time_reg_id: @time_reg.id, date: @target_date.to_s }
    end
    assert_equal @user, TimeReg.order(:created_at).last.user, "the copy stays with the original owner"
  end

  test "spectator cannot copy anything" do
    sign_in users(:organization_spectator)

    assert_no_difference("TimeReg.count") do
      post :create, params: { time_reg_id: @time_reg.id, date: @target_date.to_s }
    end
    assert_redirected_to reports_path
  end
end
