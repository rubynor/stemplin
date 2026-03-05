require_relative "tool_test_helper"

class ListClientsToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
  end

  test "returns clients for organization" do
    result = call_tool(ListClientsTool, user: @admin, organization: @org)
    clients = parse_result(result)

    assert_kind_of Array, clients
    assert clients.any? { |c| c["name"] == "E Corp" }
    clients.each do |c|
      assert c.key?("id")
      assert c.key?("name")
      assert c.key?("organization_id")
      assert c.key?("created_at")
      assert c.key?("updated_at")
    end
  end

  test "returns error without auth" do
    result = call_tool(ListClientsTool, organization: @org)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class ShowClientToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
    @client = clients(:e_corp)
  end

  test "returns client details" do
    result = call_tool(ShowClientTool, user: @admin, organization: @org, id: @client.id)
    client = parse_result(result)

    assert_equal @client.id, client["id"]
    assert_equal "E Corp", client["name"]
    assert_equal @org.id, client["organization_id"]
  end

  test "returns error for client in another organization" do
    other_client = clients(:f_corp)
    result = call_tool(ShowClientTool, user: @admin, organization: @org, id: other_client.id)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class CreateClientToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
  end

  test "creates a client" do
    result = call_tool(CreateClientTool, user: @admin, organization: @org, name: "New Client")
    client = parse_result(result)

    assert_equal "New Client", client["name"]
    assert_equal @org.id, client["organization_id"]
    assert client.key?("id")
  end

  test "returns error for non-admin user" do
    joe = users(:joe)
    result = call_tool(CreateClientTool, user: joe, organization: @org, name: "Forbidden Client")
    parsed = parse_result(result)
    assert parsed.key?("error")
  end

  test "returns error for invalid name" do
    result = call_tool(CreateClientTool, user: @admin, organization: @org, name: "X")
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class UpdateClientToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
    @client = clients(:e_corp)
  end

  test "updates a client" do
    result = call_tool(UpdateClientTool, user: @admin, organization: @org, id: @client.id, name: "E Corp Updated")
    client = parse_result(result)

    assert_equal @client.id, client["id"]
    assert_equal "E Corp Updated", client["name"]
  end

  test "returns error for non-admin user" do
    joe = users(:joe)
    result = call_tool(UpdateClientTool, user: joe, organization: @org, id: @client.id, name: "Nope")
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end

class DeleteClientToolTest < ToolTestCase
  setup do
    @admin = users(:organization_admin)
    @org = organizations(:organization_one)
    @client = clients(:to_be_deleted)
  end

  test "soft deletes a client" do
    result = call_tool(DeleteClientTool, user: @admin, organization: @org, id: @client.id)
    parsed = parse_result(result)

    assert_equal "deleted", parsed["status"]
    assert_equal @client.id, parsed["id"]
    assert @client.reload.discarded?
  end

  test "returns error for non-admin user" do
    joe = users(:joe)
    result = call_tool(DeleteClientTool, user: joe, organization: @org, id: @client.id)
    parsed = parse_result(result)
    assert parsed.key?("error")
  end
end
