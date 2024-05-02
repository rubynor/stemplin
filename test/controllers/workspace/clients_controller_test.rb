require "test_helper"

module  Workspace
  class ClientsControllerTest < ActionController::TestCase
    setup do
      @organization_admin = users(:organization_admin)
      sign_in @organization_admin
    end

    test "should get index" do
      get :index
      assert_response :success
    end

    test "should create a client" do
      assert_difference("Client.count") do
        post :create, params: { client: { name: "Microsoft", description: "This is microsoft" } }
      end
      assert_response :success
    end

    test "should update a client" do
      client = clients(:to_be_deleted)
      new_client_name = "Google"

      assert_not_equal client.name, new_client_name
      patch :update, params: { id: client.id, client: { name: new_client_name } }

      assert_equal client.reload.name, new_client_name
      assert_response :success
    end

    test "should destroy a client" do
      client = clients(:to_be_deleted)

      assert_difference("Client.count", -1) do
        delete :destroy, params: { id: client.id }
      end
    end
  end
end
