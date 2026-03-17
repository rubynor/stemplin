require "test_helper"

module Workspace
  class ProjectSharesControllerTest < ActionController::TestCase
    fixtures :all

    setup do
      @organization_admin = users(:organization_admin)
      sign_in @organization_admin

      @project = projects(:project_1)
      @project_share = project_shares(:project_one_shared_with_org_two)
      @org_one = organizations(:organization_one)
      @org_two = organizations(:organization_two)
    end

    # --- index ---

    test "index as org_one admin lists guest orgs for the project" do
      get :index, params: { project_id: @project.id }
      assert_response :success
    end

    test "index as org_two admin lists shared projects" do
      switch_org_context!(@organization_admin, @org_two)
      get :index, params: { project_id: @project.id }
      assert_response :success
    end

    test "index calls authorize!" do
      assert_authorized_to(:index?, ProjectShare, with: Workspace::ProjectSharePolicy) do
        get :index, params: { project_id: @project.id }
      end
    end

    # --- update ---

    test "update as org_two admin updates project_share rate and task rates" do
      switch_org_context!(@organization_admin, @org_two)
      sign_in @organization_admin
      task_rate = project_share_task_rates(:task_rate_one)

      patch :update, params: {
        project_id: @project.id,
        id: @project_share.id,
        project_share: {
          rate_currency: "5.00",
          project_share_task_rates_attributes: {
            "0" => { id: task_rate.id, rate_currency: "3.00" }
          }
        }
      }

      assert_response :redirect
      assert_equal 500, @project_share.reload.rate
      assert_equal 300, task_rate.reload.rate
    end

    test "update as org_one admin denied" do
      patch :update, params: {
        project_id: @project.id,
        id: @project_share.id,
        project_share: { rate_currency: "5.00" }
      }

      # org_one admin cannot update guest rates (update? policy denies)
      assert_redirected_to root_path
    end

    test "update calls authorize!" do
      switch_org_context!(@organization_admin, @org_two)
      assert_authorized_to(:update?, @project_share, with: Workspace::ProjectSharePolicy) do
        patch :update, params: {
          project_id: @project.id,
          id: @project_share.id,
          project_share: { rate_currency: "5.00" }
        }
      end
    end

    # --- destroy ---

    test "destroy as org_one admin disconnects guest org" do
      assert_difference("ProjectShare.count", -1) do
        delete :destroy, params: { project_id: @project.id, id: @project_share.id }
      end
      assert_redirected_to workspace_project_path(@project)
    end

    test "destroy as org_two admin disconnects own org" do
      switch_org_context!(@organization_admin, @org_two)

      assert_difference("ProjectShare.count", -1) do
        delete :destroy, params: { project_id: @project.id, id: @project_share.id }
      end
      assert_redirected_to workspace_projects_path
    end

    test "destroy as non-admin denied" do
      sign_in users(:joe)
      delete :destroy, params: { project_id: @project.id, id: @project_share.id }
      assert_redirected_to root_path
    end

    test "destroy calls authorize!" do
      assert_authorized_to(:destroy?, @project_share, with: Workspace::ProjectSharePolicy) do
        delete :destroy, params: { project_id: @project.id, id: @project_share.id }
      end
    end
  end
end
