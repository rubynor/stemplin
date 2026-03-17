require "test_helper"

module Workspace
  class ProjectShareTaskRatesControllerTest < ActionController::TestCase
    fixtures :all

    setup do
      @organization_admin = users(:organization_admin)
      sign_in @organization_admin

      @project = projects(:project_1)
      @project_share = project_shares(:project_one_shared_with_org_two)
      @task_rate = project_share_task_rates(:task_rate_one)
      @org_one = organizations(:organization_one)
      @org_two = organizations(:organization_two)
    end

    # --- create ---

    test "create as org_two admin creates a task rate on the project share" do
      switch_org_context!(@organization_admin, @org_two)
      sign_in @organization_admin
      assigned_task = assigned_task(:task_2)

      assert_difference("ProjectShareTaskRate.count", 1) do
        post :create, params: {
          project_id: @project.id,
          project_share_id: @project_share.id,
          project_share_task_rate: {
            assigned_task_id: assigned_task.id,
            rate_currency: "4.50"
          }
        }
      end

      assert_response :redirect
      new_rate = ProjectShareTaskRate.last
      assert_equal @project_share.id, new_rate.project_share_id
      assert_equal assigned_task.id, new_rate.assigned_task_id
      assert_equal 450, new_rate.rate
    end

    test "create as org_one admin denied" do
      post :create, params: {
        project_id: @project.id,
        project_share_id: @project_share.id,
        project_share_task_rate: {
          assigned_task_id: assigned_task(:task_2).id,
          rate_currency: "4.50"
        }
      }

      assert_redirected_to root_path
    end

    test "create calls authorize!" do
      switch_org_context!(@organization_admin, @org_two)
      sign_in @organization_admin

      # verify_authorized ensures authorize! is called; this would raise
      # ActionPolicy::UnauthorizedError if authorize! were missing
      post :create, params: {
        project_id: @project.id,
        project_share_id: @project_share.id,
        project_share_task_rate: {
          assigned_task_id: assigned_task(:task_2).id,
          rate_currency: "4.50"
        }
      }
      assert_response :redirect
    end

    # --- update ---

    test "update as org_two admin updates an existing task rate" do
      switch_org_context!(@organization_admin, @org_two)
      sign_in @organization_admin

      patch :update, params: {
        project_id: @project.id,
        project_share_id: @project_share.id,
        id: @task_rate.id,
        project_share_task_rate: {
          rate_currency: "7.50"
        }
      }

      assert_response :redirect
      assert_equal 750, @task_rate.reload.rate
    end

    test "update as org_one admin denied" do
      patch :update, params: {
        project_id: @project.id,
        project_share_id: @project_share.id,
        id: @task_rate.id,
        project_share_task_rate: {
          rate_currency: "7.50"
        }
      }

      assert_redirected_to root_path
    end

    test "update calls authorize!" do
      switch_org_context!(@organization_admin, @org_two)
      sign_in @organization_admin

      assert_authorized_to(:update?, @task_rate, with: Workspace::ProjectShareTaskRatePolicy) do
        patch :update, params: {
          project_id: @project.id,
          project_share_id: @project_share.id,
          id: @task_rate.id,
          project_share_task_rate: {
            rate_currency: "7.50"
          }
        }
      end
    end
  end
end
