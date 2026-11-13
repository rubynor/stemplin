require "test_helper"
module  Workspace
  class TeamMembersControllerTest < ActionController::TestCase
    setup do
      @organization_admin = users(:organization_admin)
      sign_in @organization_admin

      @project = @organization_admin.current_organization.projects.first
      @organization = @organization_admin.current_organization
    end

    teardown { FakeTripletexApi.reset }

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

    # Tripletex employee link

    def employee(id, first, last, email: nil)
      { "id" => id, "firstName" => first, "lastName" => last, "email" => email, "employeeNumber" => id.to_s }
    end

    def connect_tripletex(**options)
      TripletexIntegration.create!(organization: @organization_admin.current_organization, employee_token: "t")
      FakeTripletexApi.install(FakeTripletexApi.new(**options))
    end

    def open_edit_modal(user)
      @request.headers["Accept"] = "text/vnd.turbo-stream.html, text/html"
      put :edit_modal, params: { id: user.id }
    end

    test "edit modal lists the Tripletex employees" do
      connect_tripletex(employees: [ employee(7, "Kari", "Nordmann"), employee(8, "Ola", "Hansen") ])
      open_edit_modal users(:organization_user)

      assert_response :success
      assert_select "select[name='user[tripletex_employee_id]'] option[value='7']", text: "Kari Nordmann (7)"
      assert_select "select[name='user[tripletex_employee_id]'] option[value='8']"
    end

    test "edit modal preselects the employee with the same email when there is no link" do
      user = users(:organization_user)
      connect_tripletex(employees: [ employee(7, "Kari", "Nordmann"), employee(8, "Ola", "Hansen", email: user.email.upcase) ])
      open_edit_modal user

      assert_select "select[name='user[tripletex_employee_id]'] option[selected][value='8']"
      assert_nil user.access_info(@organization_admin.current_organization).tripletex_employee_id
    end

    test "edit modal keeps the stored link over an email match" do
      user = users(:organization_user)
      user.access_info(@organization_admin.current_organization).update!(tripletex_employee_id: 7)
      connect_tripletex(employees: [ employee(7, "Kari", "Nordmann"), employee(8, "Ola", "Hansen", email: user.email) ])
      open_edit_modal user

      assert_select "select[name='user[tripletex_employee_id]'] option[selected][value='7']"
      assert_select "select[name='user[tripletex_employee_id]'] option[selected]", count: 1
    end

    test "edit modal keeps a linked employee that is missing from the list selectable" do
      user = users(:organization_user)
      user.access_info(@organization_admin.current_organization).update!(tripletex_employee_id: 99)
      connect_tripletex(employees: [ employee(7, "Kari", "Nordmann") ])
      open_edit_modal user

      assert_select "select[name='user[tripletex_employee_id]'] option[selected][value='99']", text: "#99"
    end

    test "edit modal shows an error when Tripletex is unavailable" do
      connect_tripletex(error: "boom")
      open_edit_modal users(:organization_user)

      assert_response :success
      assert_includes response.body, I18n.t("tripletex.team_members.unavailable", message: "boom")
      assert_select "select[name='user[tripletex_employee_id]']"
    end

    test "edit modal has no Tripletex field without an integration" do
      open_edit_modal users(:organization_user)

      assert_response :success
      assert_select "select[name='user[tripletex_employee_id]']", count: 0
    end

    test "update stores the Tripletex employee on the access info" do
      user = users(:organization_user)
      connect_tripletex(employees: [ employee(7, "Kari", "Nordmann") ])
      patch :update, params: { id: user.id, user: { role: :organization_user, tripletex_employee_id: "7", project_ids: [] } }

      assert_equal 7, user.access_info(@organization_admin.current_organization).reload.tripletex_employee_id
    end

    test "the edit modal opened from the payroll page carries return_to into the form" do
      @request.headers["Accept"] = "text/vnd.turbo-stream.html, text/html"
      put :edit_modal, params: { id: users(:organization_user).id, return_to: "payroll" }

      assert_select "input[type=hidden][name=return_to][value=payroll]", count: 1
    end

    test "the edit modal opened from the team page has no return_to" do
      open_edit_modal users(:organization_user)
      assert_select "input[name=return_to]", count: 0
    end

    test "update from the payroll page refreshes the page instead of replacing the team member row" do
      user = users(:organization_user)
      connect_tripletex(employees: [ employee(7, "Kari", "Nordmann") ])
      patch :update, params: { id: user.id, return_to: "payroll", user: { role: :organization_user, tripletex_employee_id: "7", project_ids: [] } }

      assert_equal 7, user.access_info(@organization_admin.current_organization).reload.tripletex_employee_id
      assert_select "turbo-stream[action=refresh]", count: 1
      assert_select "turbo-stream[action=refresh][request-id]", count: 0
      assert_select "turbo-stream[action=replace][target=#{ActionView::RecordIdentifier.dom_id(user)}]", count: 0
      assert_equal I18n.t("notice.user_updated"), flash[:success]
    end

    test "update from the team page replaces the team member row" do
      user = users(:organization_user)
      patch :update, params: { id: user.id, user: { role: :organization_user, project_ids: [] } }

      assert_select "turbo-stream[action=replace][target=#{ActionView::RecordIdentifier.dom_id(user)}]", count: 1
      assert_select "turbo-stream[action=refresh]", count: 0
    end

    test "update with a blank employee clears the link" do
      user = users(:organization_user)
      access_info = user.access_info(@organization_admin.current_organization)
      access_info.update!(tripletex_employee_id: 7)
      connect_tripletex(employees: [ employee(7, "Kari", "Nordmann") ])
      patch :update, params: { id: user.id, user: { role: :organization_user, tripletex_employee_id: "", project_ids: [] } }

      assert_nil access_info.reload.tripletex_employee_id
    end

    test "update refuses an employee already linked to another member" do
      other = users(:organization_spectator)
      other.access_info(@organization_admin.current_organization).update!(tripletex_employee_id: 7)
      user = users(:organization_user)
      connect_tripletex(employees: [ employee(7, "Kari", "Nordmann") ])
      patch :update, params: { id: user.id, user: { role: :organization_admin, tripletex_employee_id: "7", project_ids: [] } }

      assert_response :success
      assert_includes response.body, I18n.t("tripletex.team_members.errors.employee_taken")
      assert_nil user.access_info(@organization_admin.current_organization).reload.tripletex_employee_id
      assert_equal "organization_user", user.access_info(@organization_admin.current_organization).role
    end

    test "update saves the role and keeps the link when Tripletex is unavailable" do
      user = users(:organization_user)
      access_info = user.access_info(@organization_admin.current_organization)
      access_info.update!(tripletex_employee_id: 7)
      connect_tripletex(error: "boom")
      patch :update, params: { id: user.id, user: { role: :organization_spectator, tripletex_employee_id: "7", project_ids: [] } }

      assert_equal "organization_spectator", access_info.reload.role
      assert_equal 7, access_info.tripletex_employee_id
    end

    test "update stores the submitted link without asking Tripletex" do
      user = users(:organization_user)
      fake = connect_tripletex(error: "boom")
      patch :update, params: { id: user.id, user: { role: :organization_user, tripletex_employee_id: "7", project_ids: [] } }

      assert_equal 7, user.access_info(@organization_admin.current_organization).reload.tripletex_employee_id
      assert_equal 0, fake.employees_calls
    end

    test "update clears the link when none is chosen, also when Tripletex is unavailable" do
      user = users(:organization_user)
      access_info = user.access_info(@organization_admin.current_organization)
      access_info.update!(tripletex_employee_id: 7)
      connect_tripletex(error: "boom")
      patch :update, params: { id: user.id, user: { role: :organization_user, tripletex_employee_id: "", project_ids: [] } }

      assert_nil access_info.reload.tripletex_employee_id
    end

    test "update leaves the link alone when the field is not submitted" do
      user = users(:organization_user)
      access_info = user.access_info(@organization_admin.current_organization)
      access_info.update!(tripletex_employee_id: 7)
      connect_tripletex
      patch :update, params: { id: user.id, user: { role: :organization_spectator, project_ids: [] } }

      assert_equal "organization_spectator", access_info.reload.role
      assert_equal 7, access_info.tripletex_employee_id
    end

    test "update ignores the employee param without an integration" do
      user = users(:organization_user)
      patch :update, params: { id: user.id, user: { role: :organization_user, tripletex_employee_id: "7", project_ids: [] } }

      assert_nil user.access_info(@organization_admin.current_organization).reload.tripletex_employee_id
    end
  end
end
