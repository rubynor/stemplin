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
              invite_users_hash: { "0" => {
                email: "new_user@example.com",
                role: :organization_user,
                project_ids: [ @project.id ]
              } }
            }
          end
        end
      end

      assert_redirected_to workspace_team_members_path
    end

    test "should create multiple new users and associate with organization" do
      assert_difference("User.count", 2) do
        assert_difference("AccessInfo.count", 2) do
          post :create, params: {
            invite_users_hash: {
              "1" => {
                email: "new_user1@example.com",
                role: :organization_admin,
                project_ids: []
              },
              "2" => {
                email: "new_user2@example.com",
                role: :organization_admin,
                project_ids: []
              }
            }
          }
        end
      end

      assert_redirected_to workspace_team_members_path
    end

    test "should not create/invite user with invalid email" do
      assert_no_difference("User.count") do
        assert_no_difference("AccessInfo.count") do
          assert_no_difference("ProjectAccess.count") do
            post :create, params: {
              invite_users_hash: { "0" => {
                email: "invalid_email",
                role: :organization_user,
                project_ids: [ @project.id ]
              } }
            }
          end
        end
      end

      assert_response :unprocessable_entity
    end

    test "should not create/invite user with existing email" do
      assert_no_difference("User.count") do
        assert_no_difference("AccessInfo.count") do
          assert_no_difference("ProjectAccess.count") do
            post :create, params: {
              invite_users_hash: { "0" => {
                email: @organization_admin.email,
                role: :organization_user,
                project_ids: [ @project.id ]
              } }
            }
          end
        end
      end

      assert_response :unprocessable_entity
    end

    test "should add an existing user to the organization and create project access" do
      user = users(:user_wo_access_info)
      assert_no_difference("User.count") do
        assert_difference("AccessInfo.count") do
          assert_difference("ProjectAccess.count") do
            post :create, params: {
              invite_users_hash: { "0" => {
                email: user.email,
                role: :organization_user,
                project_ids: [ @project.id ]
              } }
            }
          end
        end
      end

      assert_redirected_to workspace_team_members_path
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
                role: :organization_admin,
                project_ids: []
              }
            }
          end
        end
      end

      assert_response :success
      assert_equal "organization_admin", access_info.reload.role
    end

    test "should get invite_users form" do
      get :invite_users
      assert_response :success
      assert_equal AccessInfo.allowed_organization_roles, assigns(:roles)
    end

    test "should get edit modal with the member's current role and projects" do
      user = users(:organization_user)
      @request.headers["Accept"] = "text/vnd.turbo-stream.html, text/html"
      put :edit_modal, params: { id: user.id }

      assert_response :success
      assert_equal "organization_user", assigns(:selected_role)
      assert_equal [ @project.id ], assigns(:selected_project_ids)
    end

    test "should not open the edit modal for a user outside the organization" do
      sign_in users(:ron) # active in organization_two, but ron is only a member there
      @request.headers["Accept"] = "text/vnd.turbo-stream.html, text/html"
      put :edit_modal, params: { id: users(:joe).id }
      assert_redirected_to root_path
    end

    test "should turn a member into a spectator and keep their project access" do
      user = users(:organization_user)
      access_info = user.access_info(@organization_admin.current_organization)

      assert_no_difference("ProjectAccess.count") do
        patch :update, params: { id: user.id, user: { role: :organization_spectator, project_ids: [ @project.id ] } }
      end

      assert_response :success
      assert_equal "organization_spectator", access_info.reload.role
      assert_equal [ @project ], access_info.projects
    end

    test "should turn a spectator into a member" do
      user = users(:organization_spectator)
      access_info = user.access_info(@organization_admin.current_organization)

      patch :update, params: { id: user.id, user: { role: :organization_user, project_ids: [ @project.id ] } }

      assert_response :success
      assert_equal "organization_user", access_info.reload.role
    end

    test "member cannot see or manage the team" do
      member = users(:organization_user)
      sign_in member

      get :index
      assert_redirected_to root_path
      get :invite_users
      assert_redirected_to root_path
      @request.headers["Accept"] = "text/vnd.turbo-stream.html, text/html"
      put :edit_modal, params: { id: member.id }
      assert_redirected_to root_path

      assert_no_difference("User.count") do
        post :create, params: { invite_users_hash: { "0" => { email: "sneaky@example.com", role: :organization_admin, project_ids: [] } } }
      end
      assert_redirected_to root_path

      patch :update, params: { id: member.id, user: { role: :organization_admin, project_ids: [] } }
      assert_redirected_to root_path
      assert_equal "organization_user", member.access_info.reload.role
    end

    test "spectator cannot see or manage the team" do
      spectator = users(:organization_spectator)
      sign_in spectator

      get :index
      assert_redirected_to reports_path

      patch :update, params: { id: spectator.id, user: { role: :organization_admin, project_ids: [] } }
      assert_redirected_to reports_path
      assert_equal "organization_spectator", spectator.access_info.reload.role
    end

    test "should not allow zero admins in an organization" do
      access_infos(:access_info_org1_admin).update(active: false)
      access_infos(:access_info_org_w_one_admin).update(active: true)

      assert_equal @organization_admin.current_organization, organizations(:organization_w_one_admin)
      assert @organization_admin.current_organization.access_infos.where(role: :organization_admin).count == 1
      assert_no_difference("AccessInfo.where(role: :organization_admin).count") do
        patch :update, params: {
          id: @organization_admin.id,
          user: {
            first_name: "Newfirstname",
            last_name: @organization_admin.last_name,
            email: @organization_admin.email,
            role: :organization_user,
            project_ids: []
          }
        }
      end

      assert_response :success
      assert_not_equal "Newfirstname", @organization_admin.reload.first_name
    end
  end
end
