require "test_helper"
module  Workspace
  class TeamMembersControllerTest < ActionController::TestCase
    setup do
      @organization_admin = users(:organization_admin)
      sign_in @organization_admin

      @project = @organization_admin.current_organization.projects.first
    end

    test "should get index" do
      get :index
      assert_response :success
    end

    test "should create a new user and associate with organization" do
      assert_difference("User.count") do
        assert_difference("AccessInfo.count") do
          assert_difference("ProjectAccess.count") do
            post :create, params: {
              user: {
                email: "new_user@example.com",
                first_name: "John",
                last_name: "Doe",
                password: "password123",
                password_confirmation: "password123",
                role: :organization_user,
                project_ids: [ @project.id ]
              }
            }
          end
        end
      end

      assert_response :success
      assert_not assigns(:user).is_verified
    end

    test "should add an existing user to the organization and create project access" do
      user = users(:user_wo_access_info)
      assert_no_difference("User.count") do
        assert_difference("AccessInfo.count") do
          assert_difference("ProjectAccess.count") do
            post :add_to_organization, params: {
              user: {
                email: user.email,
                role: :organization_user,
                project_ids: [ @project.id ]
              }
            }
          end
        end
      end

      assert_response :success
      assert_equal user, assigns(:user)
      assert assigns(:user).is_verified
    end

    test "should handle missing user in add_to_organization and redirect to a new user form" do
      not_registered_user_email = "not_registered_user@test.com"

      assert_no_difference("User.count") do
        assert_no_difference("AccessInfo.count") do
          post :add_to_organization, params: {
            user: {
              email: not_registered_user_email,
              role: :organization_user
            }
          }
        end
      end

      assert_response :success
      assert_not_nil assigns(:new_user)
      assert_equal not_registered_user_email, assigns(:new_user).email
    end

    test "should update user, access_info and project accesses" do
      user = users(:ron)
      access_info = user.access_info(@organization_admin.current_organization)
      assert_no_difference("User.count") do
        assert_no_difference("AccessInfo.count") do
          assert_difference("ProjectAccess.count", -1) do
            patch :update, params: {
              id: user.id,
              user: {
                first_name: "John",
                last_name: "Doe",
                email: user.email,
                role: :organization_admin,
                project_ids: []
              }
            }
          end
        end
      end

      assert_response :success
      assert_equal "John", user.reload.first_name
      assert_equal "organization_admin", access_info.reload.role
    end
  end
end
