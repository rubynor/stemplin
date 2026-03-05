require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  def setup
    @organization_one = organizations(:organization_one)
    @organization_two = organizations(:organization_two)
  end

  test "name should not be unique accross clients" do
    @task_org_1 = tasks(:debug)
    @task_org_2 = tasks(:login)
    @organization_one.clients.first.projects.create(name: "Unique client name", description: "Lorem", assigned_tasks_attributes: [ { task_id: @task_org_1.id } ])
    assert_changes "Project.count" do
      @organization_two.clients.first.projects.create(name: "Unique client name", description: "Lorem", assigned_tasks_attributes: [ { task_id: @task_org_2.id } ])
    end
  end
end
