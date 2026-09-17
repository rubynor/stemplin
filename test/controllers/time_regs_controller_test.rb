require "test_helper"

class TimeRegsControllerTest < ActionController::TestCase
  class RegularUser < TimeRegsControllerTest
    setup do
      @user = users(:joe)
      @current_date = Date.today
      @time_reg = time_regs(:time_reg_1)
      @old_time_reg = time_regs(:time_reg_3)

      @second_user = users(:organization_user)
      @second_user_time_reg = @second_user.time_regs.last

      sign_in @user
    end

    test "should get index" do
      get :index
      assert_response :success
      assert_equal @current_date, assigns(:chosen_date)
      assert_equal @user.time_regs.on_date(@current_date).sort, assigns(:time_regs).sort
      assert_equal @user.time_regs.between_dates(@current_date.beginning_of_week, @current_date.end_of_week).sort, assigns(:time_regs_week).sort
    end

    test "should toggle_active time_reg" do
      assert_not @time_reg.active?

      assert_authorized_to(:toggle_active?, @time_reg) do
        patch :toggle_active, params: { time_reg_id: @time_reg.id }
        assert @time_reg.reload.active?
      end
    end

    test "should destroy time_reg" do
      assert_authorized_to(:destroy?, @time_reg) do
        delete :destroy, params: { id: @time_reg.id }
        assert_raises(ActiveRecord::RecordNotFound) { TimeReg.find @time_reg.id }
      end
    end

    test "should record time_reg when valid" do
      used_project = @user.current_organization.projects.first
      assert_difference("TimeReg.count") do
        post :create, params: { time_reg: { date_worked: @current_date, minutes: 60, project_id: used_project.id, assigned_task_id: used_project.assigned_tasks.first.id } }
      end
      assert_not TimeReg.last.active?
    end

    test "should record time_reg when valid and start timer when minutes where not provided" do
      used_project = @user.current_organization.projects.first
      assert_difference("TimeReg.count") do
        post :create, params: { time_reg: { date_worked: @current_date, project_id: used_project.id, assigned_task_id: used_project.assigned_tasks.first.id } }
      end

      assert TimeReg.last.active?
    end

    test "should not record time_reg when invalid" do
      assert_no_difference("TimeReg.count") do
        post :create, params: { time_reg: { date_worked: @current_date, minutes: 0, project_id: nil, assigned_task_id: nil } }
      end
    end

    test "should not start timer if another is turned on" do
      @active_time_reg = @user.time_regs.second
      @active_time_reg.toggle_active

      post :toggle_active, params: { time_reg_id: @time_reg.id }
      assert_not @time_reg.active?
    end

    test "should not create time_reg and start timer if another is turned on" do
      used_project = @user.current_organization.projects.first
      @active_time_reg = @old_time_reg
      @active_time_reg.update(start_time: 1.hour.ago)

      assert_no_difference("TimeReg.count") do
        post :create, params: { time_reg: { date_worked: @current_date, minutes: 0, project_id: used_project.id, assigned_task_id: used_project.assigned_tasks.first.id } }
      end
      assert @active_time_reg.active?
    end

    test "should update an old time_reg while another timer is running" do
      @old_time_reg
      @time_reg.update(start_time: 5.minutes.ago)
      assert @time_reg.active?

      patch :update, params: { id: @old_time_reg.id, time_reg: { notes: "Test notes" } }
      @old_time_reg = TimeReg.find @old_time_reg.id
      assert_equal "Test notes", @old_time_reg.notes
    end

    test "spectator should not be able to record time_reg" do
      used_project = @user.current_organization.projects.first
      @user.access_info.update(role: "organization_spectator")
      assert_no_difference("TimeReg.count") do
        post :create, params: { time_reg: { date_worked: @current_date, minutes: 0, project_id: used_project.id, assigned_task_id: used_project.assigned_tasks.first.id } }
      end
      assert_redirected_to reports_path
    end

    test "should not allow user to create a time_reg on behalf of another user within the same organization" do
      used_project = @second_user.current_organization.projects.first
      assert_no_difference("TimeReg.count") do
        post :create, params: { time_reg: { date_worked: @current_date, user_id: @second_user.id, project_id: used_project.id, assigned_task_id: used_project.assigned_tasks.first.id }, provide_user: true }
      end

      assert_not_equal TimeReg.last.user, @second_user
    end

    test "should not allow user to update a time_reg on behalf of another user within the same organization" do
      new_note = "just testing out time_reg update"
      last_user_time_reg = @second_user.time_regs.last

      patch :update, params: { id: last_user_time_reg.id, time_reg: { notes: new_note } }
      assert_not_equal new_note, last_user_time_reg.reload.notes
    end

    test "should not allow user to delete a time_reg on behalf of another user within the same organization" do
      time_reg = @second_user.time_regs.last

      assert_authorized_to(:destroy?, time_reg) do
        delete :destroy, params: { id: time_reg.id }
      end

      assert TimeReg.exists?(time_reg.id)
    end
  end

  class AdminUser < TimeRegsControllerTest
    setup do
      @admin = users(:organization_admin)
      @user = users(:organization_user)
      @current_date = Date.today

      sign_in @admin
    end

    test "should allow admin to create a time_reg on behalf of another user within the same organization" do
      used_project = @user.current_organization.projects.first
      assert_difference("TimeReg.count") do
        post :create, params: { time_reg: { date_worked: @current_date, user_id: @user.id, project_id: used_project.id, assigned_task_id: used_project.assigned_tasks.first.id }, provide_user: true }
      end

      assert_equal TimeReg.last.user, @user
    end

    test "should allow admin to update a time_reg on behalf of another user within the same organization" do
      new_note = "just testing out time_reg update"
      last_user_time_reg = @user.time_regs.last

      assert_not_equal new_note, last_user_time_reg.notes

      patch :update, params: { id: last_user_time_reg.id, time_reg: { notes: new_note } }
      assert_equal new_note, last_user_time_reg.reload.notes
    end

    test "should allow admin to delete a time_reg on behalf of another user within the same organization" do
      time_reg = @user.time_regs.last

      assert_authorized_to(:destroy?, time_reg) do
        delete :destroy, params: { id: time_reg.id }
        assert_raises(ActiveRecord::RecordNotFound) { TimeReg.find time_reg.id }
      end
    end
  end

  class Export < TimeRegsControllerTest
    setup do
      @admin = users(:organization_admin)
      @project = @admin.current_organization.projects.first
      sign_in @admin
    end

    test "should export the project's time regs as csv" do
      time_reg = @project.time_regs.first
      assert_not_nil time_reg, "fixture project is expected to have time registrations"

      get :export, params: { project_id: @project.id }

      assert_response :success
      assert_match(/\.csv"?$/, response.headers["Content-Disposition"].to_s.split("filename=").last.to_s.delete('"'))

      rows = CSV.parse(response.body)
      assert_equal [ "date", "client", "project", "task", "notes", "minutes", "first name", "last name", "email" ], rows.first
      assert_equal @project.time_regs.count, rows.size - 1

      exported = rows[1..].find { |row| row[4] == time_reg.notes }
      assert_not_nil exported, "expected the time registration to be part of the export"
      assert_equal @project.client.name, exported[1]
      assert_equal @project.name, exported[2]
      assert_equal time_reg.user.email, exported[8]
    end

    test "should not export a project belonging to another organization" do
      sign_in users(:ron) # active in organization_two, the project is in organization_one

      assert_raises(ActiveRecord::RecordNotFound) do
        get :export, params: { project_id: @project.id }
      end
    end

    test "spectators are not allowed to export" do
      sign_in users(:organization_spectator)

      get :export, params: { project_id: @project.id }

      assert_redirected_to reports_path
    end
  end
end
