require "test_helper"

module  Workspace
  class TasksControllerTest < ActionController::TestCase
    setup do
      @organization_admin = users(:organization_admin)
      sign_in @organization_admin
    end

    test "should get index" do
      get :index
      assert_response :success
    end

    test "should create a task" do
      assert_difference("Task.count") do
        post :create, params: { task: { name: "Task" } }
      end
      assert_response :success
    end

    test "should update a task" do
      task = tasks(:coding)
      new_task_name = "Task"

      assert_not_equal task.name, new_task_name
      patch :update, params: { id: task.id, task: { name: new_task_name } }

      assert_equal task.reload.name, new_task_name
      assert_response :success
    end

    test "should not destroy a task if it is assigned to a project" do
      task = tasks(:coding)

      assert_no_difference("Task.count") do
        delete :destroy, params: { id: task.id }
      end
    end

    test "should destroy a task without assigned tasks" do
      task = tasks(:no_assigned_tasks)

      assert_difference("Task.count", -1) do
        delete :destroy, params: { id: task.id }
      end
    end
  end
end
