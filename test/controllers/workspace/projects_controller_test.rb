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
  end
end
