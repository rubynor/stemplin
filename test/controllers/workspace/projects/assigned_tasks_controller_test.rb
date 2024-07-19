require "test_helper"

module Workspace
  module Projects
    class AssignedTasksControllerTest < ActionController::TestCase
      setup do
        @organization_admin = users(:organization_admin)
        sign_in @organization_admin
      end

      test "should get add_modal" do
        post :add_modal, xhr: true
        assert_response :success
      end

      test "should add assigned task from exsting task" do
        task = @organization_admin.current_organization.tasks.first
        post :add, params: { assigned_task: { task_attributes: { name: task.name }, rate_nok: 100 } }
        assert_response :success
      end

      test "should add assigned task from new task" do
        post :add, params: { assigned_task: { task_attributes: { name: "New task name" }, rate_nok: 0 } }
        assert_response :success
      end

      test "should not add assigned task without task" do
        post :add, params: { assigned_task: { task_attributes: { name: "" }, rate_nok: 100 } }
        assert_response :unprocessable_entity
      end

      test "should remove persisted assigned_task" do
        assigned_task = @organization_admin.current_organization.assigned_tasks.first
        delete :remove, params: { id: assigned_task.id, domid: "example_dom_id" }
        assert_response :success
      end

      test "should remove unpersisted assigned_task" do
        delete :remove, params: { id: nil, domid: "example_dom_id" }
        assert_response :success
      end
    end
  end
end
