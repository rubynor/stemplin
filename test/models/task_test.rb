require "test_helper"

class TaskTest < ActiveSupport::TestCase
  def setup
    @organization_one = organizations(:organization_one)
    @organization_two = organizations(:organization_two)
  end

  test "name should not be unique accross organizations" do
    @organization_one.tasks.create(name: "Unique task name")
    assert_changes 'Task.count' do
      @organization_two.tasks.create(name: "Unique task name")
    end
  end
end
