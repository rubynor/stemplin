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
      assert_redirected_to root_path
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
  end
end
