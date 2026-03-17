require "test_helper"

module Workspace
  class ProjectsControllerTest < ActionController::TestCase
    setup do
      @organization_admin = users(:organization_admin)
      sign_in @organization_admin

      @client = @organization_admin.current_organization.clients.first
      @tasks = @organization_admin.current_organization.tasks
      @project = @organization_admin.current_organization.projects.first
    end

    test "should get index" do
      get :index
      assert_response :success
    end

    test "should create project" do
      task = tasks(:e2e_testing)
      user = users(:organization_user)
      assert_difference("Project.count") do
        assert_difference("AssignedTask.count") do
          post :create, params: { project: {
            name: "Test Project",
            description: "Project description",
            billable: true,
            rate_currency: 100,
            client_id: @client.id,
            user_ids: [ user.id ],
            assigned_tasks_attributes: [
              { task_id: task.id }
            ]
          } }
        end
      end
      new_project = @organization_admin.current_organization.projects.last
      assert_equal "Test Project", new_project.name
      assert_redirected_to workspace_project_path(new_project)
    end

    test "should not create project without assigned_tasks" do
      user = users(:organization_user)
      assert_no_difference("Project.count") do
        post :create, params: { project: {
          name: "Test Project",
          description: "Project description",
          billable: true,
          rate_currency: 100,
          client_id: @client.id,
          user_ids: [ user.id ]
        } }
      end
      assert_response :unprocessable_entity
    end

    test "should show project" do
      get :show, params: { id: @project.id }
      assert_response :success
    end

    test "spectator should not show project" do
      sign_in users(:organization_spectator)
      get :show, params: { id: @project.id }
      assert_redirected_to reports_path
    end

    test "should update project" do
      user = users(:ron)
      patch :update, params: { id: @project.id, project: { name: "Updated Project", user_ids: [ user.id ] } }

      assert_redirected_to workspace_project_path(@project)
      assert @project.name, "Updated Project"
    end

    test "should destroy project" do
      to_delete_project = projects(:to_be_deleted)
      assert_difference("Project.count", -1) do
        delete :destroy, params: { id: to_delete_project.id }
      end

      assert_response :redirect
    end

    test "should archive assigned_task task with time_regs" do
      active_assigned_task = @project.active_assigned_tasks.first

      assert_difference("@project.active_assigned_tasks.count", -1) do
        patch :update, params: { id: @project.id, project: { assigned_tasks_attributes: [ { id: active_assigned_task.id, _destroy: true } ] } }
      end
      assert_redirected_to workspace_project_path(@project)
    end

    # --- Shared project tests (guest org admin) ---

    test "org_two admin can access show for a shared project" do
      shared_project = projects(:project_1)
      switch_org_context!(@organization_admin, organizations(:organization_two))
      sign_in @organization_admin

      get :show, params: { id: shared_project.id }
      assert_response :success
      assert assigns(:shared_project), "Expected @shared_project to be set for guest org admin"
      assert_not_nil assigns(:project_share), "Expected @project_share to be set for guest org admin"
    end

    test "org_one admin sees guest_organizations for owned shared project" do
      get :show, params: { id: @project.id }
      assert_response :success
      assert_not assigns(:shared_project), "Expected @shared_project to be false for owning org admin"
      assert_not_nil assigns(:guest_organizations), "Expected @guest_organizations to be set for owning org admin"
    end

    test "org_two admin sees shared projects in index" do
      switch_org_context!(@organization_admin, organizations(:organization_two))
      sign_in @organization_admin

      get :index
      assert_response :success
    end

    test "org_two admin cannot access edit for shared project" do
      shared_project = projects(:project_1)
      switch_org_context!(@organization_admin, organizations(:organization_two))
      sign_in @organization_admin

      get :edit, params: { id: shared_project.id }
      assert_redirected_to root_path
    end

    test "org_two admin cannot access update for shared project" do
      shared_project = projects(:project_1)
      switch_org_context!(@organization_admin, organizations(:organization_two))
      sign_in @organization_admin

      patch :update, params: { id: shared_project.id, project: { name: "Hacked Name" } }
      assert_redirected_to root_path
      assert_equal "E Corp CRM", shared_project.reload.name
    end

    test "org_two admin cannot access destroy for shared project" do
      shared_project = projects(:project_1)
      switch_org_context!(@organization_admin, organizations(:organization_two))
      sign_in @organization_admin

      assert_no_difference("Project.count") do
        delete :destroy, params: { id: shared_project.id }
      end
      assert_redirected_to root_path
    end
  end
end
