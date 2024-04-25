require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  def setup
    @organization_one = organizations(:organization_one)
    @organization_two = organizations(:organization_two)
  end

  test "name should not be unique accross clients" do
    @organization_one.clients.first.projects.create(name: "Unique client name", description: "Lorem")
    assert_changes "Project.count" do
      @organization_two.clients.first.projects.create(name: "Unique client name", description: "Lorem")
    end
  end
end
