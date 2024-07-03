require "test_helper"

class ProjectAccessTest < ActiveSupport::TestCase
  def setup
    @normal_user_access_info = access_infos(:access_info_org1_user)
    @admin_access_info = access_infos(:access_info_org1_admin)
    @project = projects(:project_1)
    @project_access = ProjectAccess.new(project: @project, access_info: @normal_user_access_info)
  end

  test "should be valid for normal user" do
    assert @project_access.valid?
  end

  test "should not be valid for admin" do
    @project_access.access_info = @admin_access_info
    assert_not @project_access.valid?
  end

  test "should not allow duplicate project access" do
    duplicate_project_access = @project_access.dup
    @project_access.save
    assert_not duplicate_project_access.valid?
  end
end
