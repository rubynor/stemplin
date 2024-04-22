require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:ron)
    @organization_one = organizations(:organization_one)
    @organization_two = organizations(:organization_two)
    @organization_three = organizations(:organization_three)
  end

  test "user should change to related organization" do
    assert_equal @organization_two, @user.current_organization

    result = @user.set_organization(@organization_one)

    assert_equal true, result
    assert_equal @organization_one, @user.current_organization
  end

  test "user should not change to unrelated organization" do
    assert_equal @organization_two, @user.current_organization

    result = @user.set_organization(@organization_three)

    assert_equal false, result
    assert_not_equal @organization_three, @user.current_organization
    assert_equal @organization_two, @user.current_organization
  end
end
