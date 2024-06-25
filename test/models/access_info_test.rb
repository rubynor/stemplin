require "test_helper"

class AccessInfoTest < ActiveSupport::TestCase
  setup do
    @user = users(:user_wo_access_info)
    @organization = organizations(:organization_one)
  end

  test "should not save access_info without user" do
    access_info = AccessInfo.new(organization: @organization)
    assert_not access_info.save
  end

  test "should not save access_info without organization" do
    access_info = AccessInfo.new(user: @user)
    assert_not access_info.save
  end

  test "should save access_info with user and organization" do
    access_info = AccessInfo.new(user: @user, organization: @organization)
    assert access_info.valid?
    assert access_info.save
  end

  test "should not save access_info with duplicate user_id and organization_id" do
    AccessInfo.create(user: @user, organization: @organization)
    access_info = AccessInfo.new(user: @user, organization: @organization)
    assert_not access_info.save
    assert_not access_info.valid?
  end

  test "should return allowed organization roles" do
    assert_equal AccessInfo.allowed_organization_roles, %w[organization_user organization_admin]
  end
end
