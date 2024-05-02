require "test_helper"

module Workspace
  module Projects
    class TasksControllerTest < ActionController::TestCase
      setup do
        @organization_admin = users(:organization_admin)
        sign_in @organization_admin
        @project = @organization_admin.current_organization.projects.first
      end


      test "should create task and assign it to the project" do
        new_task_name = "New Login task"
        assert_difference("Task.count") do
          assert_difference("AssignedTask.count") do
            post :create, params: { project_id: @project.id, task: { name: new_task_name, assigned_tasks_attributes: [ { rate_nok: 100, project_id: @project.id } ] } }
          end
        end

        assert_response :success
        assert_equal @project.reload.assigned_tasks.last.task.name, new_task_name
      end
    end
  end
end
