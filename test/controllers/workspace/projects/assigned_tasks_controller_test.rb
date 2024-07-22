require "test_helper"

module Workspace
  module Projects
    class AssignedTasksControllerTest < ActionController::TestCase
      setup do
        @organization_admin = users(:organization_admin)
        sign_in @organization_admin
        @project = @organization_admin.current_organization.projects.first
        @tasks = @organization_admin.current_organization.tasks
        @archived_assigned_task = assigned_task(:task_2_archived)
      end

      test "should create assigned task" do
        assert_difference("AssignedTask.count") do
          post :create, params: { project_id: @project.id, assigned_task: { task_attributes: { id: @tasks.first.id }, rate_nok: 100 } }
        end

        assert_response :success
      end

      test "should not create assigned task without task" do
        assert_no_difference("AssignedTask.count") do
          post :create, params: { project_id: @project.id, assigned_task: { task_attributes: { id: nil }, rate_nok: 100 } }
        end
      end

      test "should not create an assigned task with a task not belonging to the organization" do
        organization_two = organizations(:organization_two)
        task = organization_two.tasks.first

        assert_no_difference("AssignedTask.count") do
          post :create, params: { project_id: @project.id, assigned_task: { task_attributes: { id: task.id }, rate_nok: 100 } }
        end
      end

      test "should update assigned_task(task)" do
        assigned_task = @project.assigned_tasks.first

        new_name = "New name"
        patch :update, params: { id: assigned_task.id, project_id: assigned_task.project.id, assigned_task: { task_attributes: { id: assigned_task.task.id, name: new_name } } }
        assert_response :success

        assert_equal assigned_task.reload.task.name, new_name
      end

      test "should not update archived assigned task" do
        assigned_task = @archived_assigned_task

        new_name = "New name"
        patch :update, params: { id: assigned_task.id, project_id: assigned_task.project.id, assigned_task: { task_attributes: { id: assigned_task.task.id, name: new_name } } }

        assert_not_equal assigned_task.reload.task.name, new_name
      end

      test "should remove assigned_task from the project but not delete the task" do
        assigned_task = @project.assigned_tasks.first

        assert_difference("AssignedTask.count", -1) do
          delete :destroy, params: { id: assigned_task.id, project_id: assigned_task.project.id }
        end

        assert_response :success
        assert_not_nil Task.find(assigned_task.task.id)
      end
    end
  end
end
