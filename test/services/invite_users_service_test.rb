require "test_helper"

class InviteUsersServiceTest < ActiveSupport::TestCase
  setup do
    @organization_admin = users(:organization_admin)
    @project1 = @organization_admin.current_organization.projects.first
    @project2 = @organization_admin.current_organization.projects.second
  end

  test "should create a new user and associate with organization" do
    invite_users_hash = {
      "0" => InviteUserForm.new({
        email: "new_user@gmail.com",
        role: "organization_user",
        project_ids: [ @project1.id ]
      }, @organization_admin.current_organization)
    }
    assert_difference("User.count") do
      assert_difference("AccessInfo.count") do
        assert_difference("ProjectAccess.count") do
          assert InviteUsersService.new(invite_users_hash, @organization_admin).call
        end
      end
    end
  end

  test "should create multiple new users and associate with organization" do
    invite_users_hash = {
      "1" => InviteUserForm.new({
        email: "new_user1@gmail.com",
        role: "organization_admin",
        project_ids: []
      }, @organization_admin.current_organization),
      "2" => InviteUserForm.new({
        email: "new_user2@gmail.com",
        role: "organization_user",
        project_ids: []
      }, @organization_admin.current_organization)
    }
    assert_difference("User.count", 2) do
      assert_difference("AccessInfo.count", 2) do
        assert InviteUsersService.new(invite_users_hash, @organization_admin).call
      end
    end
  end

  test "should invite existing user with no access info to organization" do
    user_wo_access_info = users(:user_wo_access_info)
    invite_users_hash = {
      "0" => InviteUserForm.new({
        email: user_wo_access_info.email,
        role: "organization_user",
        project_ids: [ @project1.id, @project2.id ]
      }, @organization_admin.current_organization)
    }
    assert_no_difference("User.count") do
      assert_difference("AccessInfo.count") do
        assert_difference("ProjectAccess.count", 2) do
          assert InviteUsersService.new(invite_users_hash, @organization_admin).call
        end
      end
    end
  end

  test "should not create/invite user with invalid email" do
    invite_users_hash = {
      "0" => InviteUserForm.new({
        email: "invalid_email",
        role: "organization_user",
        project_ids: [ @project1.id ]
      }, @organization_admin.current_organization)
    }
    assert_no_difference("User.count") do
      assert_no_difference("AccessInfo.count") do
        assert_no_difference("ProjectAccess.count") do
          assert_not InviteUsersService.new(invite_users_hash, @organization_admin).call
        end
      end
    end
  end

  test "should not create/invite user with invalid role" do
    invite_users_hash = {
      "0" => InviteUserForm.new({
        email: "new_user@gmail.com",
        role: "invalid_role",
        project_ids: [ @project1.id ]
      }, @organization_admin.current_organization)
    }
    assert_no_difference("User.count") do
      assert_no_difference("AccessInfo.count") do
        assert_no_difference("ProjectAccess.count") do
          assert_not InviteUsersService.new(invite_users_hash, @organization_admin).call
        end
      end
    end
  end

  test "should not create/invite confirmed user with existing email" do
    invite_users_hash = {
      "0" => InviteUserForm.new({
        email: @organization_admin.email,
        role: "organization_user",
        project_ids: [ @project1.id ]
      }, @organization_admin.current_organization)
    }
    assert_no_difference("User.count") do
      assert_no_difference("AccessInfo.count") do
        assert_no_difference("ProjectAccess.count") do
          assert_not InviteUsersService.new(invite_users_hash, @organization_admin).call
        end
      end
    end
  end
end
