require "test_helper"

module Workspace
  class HolidaysPolicyTest < ActiveSupport::TestCase
    fixtures :all

    test "organization members can view holidays" do
      user = users(:organization_admin)
      organization = user.current_organization
      assert HolidaysPolicy.new(organization, user: user).show?
    end

    test "users without organization cannot view holidays" do
      user = users(:user_wo_access_info)
      organization = organizations(:organization_one)
      assert_not HolidaysPolicy.new(organization, user: user).show?
    end

    test "organization admins can update holidays" do
      user = users(:organization_admin)
      organization = user.current_organization
      assert HolidaysPolicy.new(organization, user: user).update?
    end

    test "organization members cannot update holidays" do
      user = users(:organization_user)
      organization = user.current_organization
      assert_not HolidaysPolicy.new(organization, user: user).update?
    end
  end
end
