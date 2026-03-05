require "test_helper"

class AssignedTaskTest < ActiveSupport::TestCase
  setup do
    @project = projects(:project_1)
    @task = tasks(:debug)
  end

  test "assigning a task to a project creates a new AssignedTask" do
    assert_difference("AssignedTask.count") do
      AssignedTask.create!(project: @project, task: @task)
    end
  end

  test "assigned task is not archived and has a rate of 0 initially" do
    assigned_task = AssignedTask.create!(project: @project, task: @task)

    assert_equal assigned_task.rate, 0
    assert_not assigned_task.is_archived?
  end

  test "should archive assigned task when rate changes" do
    new_assigned_task = AssignedTask.create!(project: @project, task: @task)
    assert_not new_assigned_task.is_archived
    assert_equal new_assigned_task.rate, 0
    assert AssignedTask.active_task.include?(new_assigned_task)

    # update rate
    assert_difference("AssignedTask.count") do
      new_assigned_task.update!(rate: 200)
    end

    # old assigned task should be archived, and only used for historical purposes
    assert new_assigned_task.is_archived
    assert_equal new_assigned_task.rate, 0
    assert_not AssignedTask.active_task.include?(new_assigned_task)

    # newly created assigned task should not be archived and will be the one with the new rate
    last_assigned_task = AssignedTask.last
    assert_not last_assigned_task.is_archived
    assert_equal last_assigned_task.rate, 200
    assert AssignedTask.active_task.include?(last_assigned_task)

    # newly created assigned task should have the same project and task as the old one
    assert_equal last_assigned_task.project, @project
    assert_equal last_assigned_task.task, @task
  end
end
