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
      assert_difference("Project.count") do
        post :create, params: { project: { name: "Test Project", description: "Project description", billable: true, rate_nok: 100, client_id: @client.id, task_ids: [ task.id ] } }
      end

      assert_response :success
    end

    test "should show project" do
      get :show, params: { id: @project.id }
      assert_response :success
    end

    test "should update project" do
      patch :update, params: { id: @project.id, project: { name: "Updated Project" } }
      assert_response :success
    end

    test "should destroy project" do
      to_delete_project = projects(:to_be_deleted)
      assert_difference("Project.count", -1) do
        delete :destroy, params: { id: to_delete_project.id }
      end

      assert_response :success
    end

    test "should archive assigned_task task with time_regs" do
      task_ids = @project.tasks.ids
      task_ids.pop

      assert_difference("@project.active_assigned_tasks.count", -1) do
        patch :update, params: { id: @project.id, project: { task_ids: task_ids } }
      end
    end

    test "should create assigned_task task" do
      project_tasks = @project.tasks
      non_project_task = @tasks.where.not(id: project_tasks).first
      task_ids = project_tasks.ids + [ non_project_task.id ]

      assert_difference("AssignedTask.count", 1) do
        patch :update, params: { id: @project.id, project: { task_ids: task_ids } }
      end

      assert_equal non_project_task, AssignedTask.last.task
      assert_not AssignedTask.last.is_archived
      assert_equal @project, AssignedTask.last.project
    end
  end
end
