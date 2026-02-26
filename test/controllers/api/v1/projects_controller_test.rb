require "test_helper"
require_relative "base_test"

class Api::V1::ProjectsControllerTest < Api::V1::BaseTest
  setup do
    @admin = users(:organization_admin)
    @user = users(:joe)
    @project = projects(:project_1)
  end

  test "index returns scoped projects" do
    get api_v1_projects_path, headers: api_headers(@admin)
    assert_response :success

    projects = json_response
    assert_kind_of Array, projects
    assert projects.any? { |p| p["name"] == "E Corp CRM" }
  end

  test "show returns project with assigned tasks" do
    get api_v1_project_path(@project), headers: api_headers(@admin)
    assert_response :success

    assert_equal "E Corp CRM", json_response["name"]
    assert json_response.key?("assigned_tasks")
    assert_kind_of Array, json_response["assigned_tasks"]
  end

  test "create project as admin" do
    client = clients(:e_corp)
    task = tasks(:e2e_testing)
    assert_difference("Project.count") do
      post api_v1_projects_path,
        params: { project: {
          name: "New API Project", client_id: client.id, rate_currency: "0", billable: false,
          assigned_tasks_attributes: [ { task_id: task.id } ]
        } },
        headers: api_headers(@admin)
    end
    assert_response :created
  end

  test "update project as admin" do
    patch api_v1_project_path(@project),
      params: { project: { name: "Updated Project Name" } },
      headers: api_headers(@admin)
    assert_response :success
    assert_equal "Updated Project Name", json_response["name"]
  end

  test "destroy project as admin" do
    project = projects(:to_be_deleted)
    delete api_v1_project_path(project), headers: api_headers(@admin)
    assert_response :no_content
  end

  test "non-admin cannot create project" do
    client = clients(:e_corp)
    assert_no_difference("Project.count") do
      post api_v1_projects_path,
        params: { project: { name: "Should Fail", client_id: client.id, rate_currency: "0" } },
        headers: api_headers(@user)
    end
    assert_response :forbidden
  end
end
