require "test_helper"

class OrganizationsControllerTest < ActionController::TestCase
  def setup
    @user = users(:ron)
    @organization_one = organizations(:organization_one)
    @organization_two = organizations(:organization_two)
    @organization_three = organizations(:organization_three)

    sign_in @user
  end

  test "user should change to related organization" do
    assert_equal @organization_two, @user.current_organization

    post :set_current_organization, params: { id: @organization_one.id }

    assert_equal @organization_one, @user.current_organization
  end

  test "user should not change to unrelated organization" do
    assert_equal @organization_two, @user.current_organization

    post :set_current_organization, params: { id: @organization_three.id }

    assert_not_equal @organization_three, @user.current_organization
    assert_equal @organization_two, @user.current_organization
  end
end
