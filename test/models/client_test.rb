require "test_helper"

class ClientTest < ActiveSupport::TestCase
  def setup
    @organization_one = organizations(:organization_one)
    @organization_two = organizations(:organization_two)
  end

  test "name should not be unique accross organizations" do
    @organization_one.clients.create(name: "Unique client name", description: "Lorem")
    assert_changes "Client.count" do
      @organization_two.clients.create(name: "Unique client name", description: "Lorem")
    end
  end
end
