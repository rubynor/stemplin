require "test_helper"
require_relative "base_test"

class Api::V1::ClientsControllerTest < Api::V1::BaseTest
  setup do
    @admin = users(:organization_admin)
    @user = users(:joe)
    @client = clients(:e_corp)
  end

  test "index returns scoped clients for admin" do
    get api_v1_clients_path, headers: api_headers(@admin)
    assert_response :success

    clients = json_response
    assert_kind_of Array, clients
    assert clients.any? { |c| c["name"] == "E Corp" }
  end

  test "show returns client details" do
    get api_v1_client_path(@client), headers: api_headers(@admin)
    assert_response :success
    assert_equal "E Corp", json_response["name"]
  end

  test "create client as admin" do
    assert_difference("Client.count") do
      post api_v1_clients_path,
        params: { client: { name: "New API Client" } },
        headers: api_headers(@admin)
    end
    assert_response :created
    assert_equal "New API Client", json_response["name"]
  end

  test "update client as admin" do
    patch api_v1_client_path(@client),
      params: { client: { name: "Updated Name" } },
      headers: api_headers(@admin)
    assert_response :success
    assert_equal "Updated Name", json_response["name"]
  end

  test "destroy client as admin" do
    client = clients(:to_be_deleted)
    delete api_v1_client_path(client), headers: api_headers(@admin)
    assert_response :no_content
  end

  test "non-admin cannot create client" do
    assert_no_difference("Client.count") do
      post api_v1_clients_path,
        params: { client: { name: "Should Fail" } },
        headers: api_headers(@user)
    end
    assert_response :forbidden
  end
end
