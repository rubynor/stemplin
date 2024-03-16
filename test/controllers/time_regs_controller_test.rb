require "test_helper"

class TimeRegsControllerTest < ActionController::TestCase
  setup do
    @user = users(:joe)
    @current_date = Date.today
    @time_reg = @user.time_regs.first

    sign_in @user
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_equal @current_date, assigns(:chosen_date)
    assert_equal @user.time_regs.on_date(@current_date), assigns(:time_regs)
    assert_equal @user.time_regs.between_dates(@current_date.beginning_of_week, @current_date.end_of_week), assigns(:time_regs_week)
  end

  test "should toggle_active time_reg" do
    assert_not @time_reg.active

    patch :toggle_active, params: { time_reg_id: @time_reg.id }
    assert_redirected_to time_regs_path
    assert @time_reg.reload.active
  end

  test "should destroy time_reg" do
    assert_difference('TimeReg.count', -1) do
      delete :destroy , params: { id: @time_reg.id }
    end

    assert_redirected_to root_path(date: @time_reg.date_worked)
  end

  test "should record time_reg when valid" do
    assert_difference('TimeReg.count') do
      post :create, params: { time_reg: { date_worked: @current_date, minutes: 60, project_id: @user.projects.first.id, assigned_task_id: assigned_task(:task_1) } }
    end

    assert_redirected_to root_path(date: @current_date)
    assert_not TimeReg.last.active
  end

  test "should record time_reg when valid and start timer when minutes where not provided" do
    assert_difference('TimeReg.count') do
      post :create, params: { time_reg: { date_worked: @current_date, project_id: @user.projects.first.id, assigned_task_id: assigned_task(:task_2) } }
    end

    assert_redirected_to root_path(date: @current_date)
    assert TimeReg.last.active
  end

  test "should not record time_reg when invalid" do
    assert_no_difference('TimeReg.count') do
      post :create, params: { time_reg: { date_worked: @current_date, minutes: 0, project_id: nil, assigned_task_id: nil } }
    end

    assert_response :unprocessable_entity
  end
end
