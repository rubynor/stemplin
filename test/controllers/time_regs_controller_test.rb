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

  class SharedProjectMember < TimeRegsControllerTest
    setup do
      @ron = users(:ron)
      @org_two = organizations(:organization_two)
      @shared_project = projects(:project_1)
      @current_date = Date.today

      # Switch ron to org_two context
      switch_org_context!(@ron, @org_two)
      sign_in @ron
    end

    test "org_two member can create a time_reg on a shared project" do
      assigned_task = @shared_project.assigned_tasks.first
      assert_difference("TimeReg.count") do
        post :create, params: { time_reg: { date_worked: @current_date, minutes: 60, project_id: @shared_project.id, assigned_task_id: assigned_task.id } }
      end
      assert_redirected_to time_regs_path(date: @current_date)
      assert_equal @ron, TimeReg.last.user
      assert_equal assigned_task, TimeReg.last.assigned_task
    end

    test "task dropdown loads org_one tasks for the shared project" do
      get :update_tasks_select, params: { project_id: @shared_project.id }
      assert_response :success

      # Should include active tasks from project_1 (debug, coding, authentication)
      active_task_ids = @shared_project.assigned_tasks.where(is_archived: false).pluck(:id)
      returned_ids = assigns(:name_id_pairs).map(&:last)
      active_task_ids.each do |task_id|
        assert_includes returned_ids, task_id
      end
    end

    test "shared project appears in set_clients for org_two member" do
      get :index
      assert_response :success
      project_names = assigns(:clients).flat_map { |c| c.items.map(&:name) }
      assert_includes project_names, @shared_project.name
    end

  end

  class SharedProjectAdmin < TimeRegsControllerTest
    setup do
      @admin = users(:organization_admin)
      @org_two = organizations(:organization_two)
      @shared_project = projects(:project_1)
      @current_date = Date.today

      # Switch admin to org_two context
      switch_org_context!(@admin, @org_two)
      sign_in @admin
    end

    test "org_two admin can view time_regs on shared projects via index" do
      get :index
      assert_response :success
    end

    test "org_two admin can export shared project time_regs" do
      get :export, params: { project_id: @shared_project.id }
      assert_response :success
      assert_equal "text/csv", response.media_type
    end

    test "export strips email for cross-org users on shared project" do
      get :export, params: { project_id: @shared_project.id }
      csv_lines = response.body.split("\n")
      # Header has "email" column
      header = csv_lines.first
      assert_includes header, "email"

      # Find rows for org_one users (e.g., joe) - their emails should be redacted
      joe = users(:joe)
      csv_lines[1..].each do |line|
        fields = CSV.parse_line(line)
        next unless fields[6] == joe.first_name && fields[7] == joe.last_name
        assert_equal "", fields[8], "Cross-org user email should be blank"
      end
    end

  end
end
