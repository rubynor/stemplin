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

  test "user is sent back to the page they came from" do
    @request.env["HTTP_REFERER"] = "/reports"
    post :set_current_organization, params: { id: @organization_one.id }
    assert_redirected_to "/reports"
  end

  test "spectator cannot switch to an organization they are not part of" do
    spectator = users(:organization_spectator)
    sign_in spectator

    post :set_current_organization, params: { id: @organization_two.id }

    assert_redirected_to reports_path
    assert_equal @organization_one, spectator.reload.current_organization
  end

  test "admin switches organization and the role of the new organization applies" do
    admin = users(:organization_admin)
    sign_in admin
    assert admin.organization_admin?

    post :set_current_organization, params: { id: @organization_two.id }
    assert_equal @organization_two, admin.reload.current_organization

    ron_in_org_two = users(:ron)
    sign_in ron_in_org_two
    post :set_current_organization, params: { id: @organization_one.id }
    assert_equal @organization_one, ron_in_org_two.reload.current_organization
    assert_not ron_in_org_two.organization_admin?, "ron is a plain member of organization_one"
  end

  test "user should not change to unrelated organization" do
    assert_equal @organization_two, @user.current_organization

    post :set_current_organization, params: { id: @organization_three.id }

    assert_not_equal @organization_three, @user.current_organization
    assert_equal @organization_two, @user.current_organization
  end
end
