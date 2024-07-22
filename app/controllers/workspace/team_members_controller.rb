module Workspace
  class TeamMembersController < WorkspaceController
    def index
      authorize!
      @pagy, @users = pagy authorized_scope(User, type: :relation).ordered_by_role.ordered_by_name
    end

    def invite_users
      authorize!
      @invite_users_hash = {}
      prepare_form_data
    end

    def create
      authorize!
      @invite_users_hash = invite_users_params.transform_values { |user_params| InviteUserForm.new(user_params, current_user.current_organization) }
      service = InviteUsersService.new(@invite_users_hash, current_user)
      if service.call
        flash[:success] = I18n.t("notice.members_invited")
        redirect_to workspace_team_members_path
      else
        prepare_form_data
        flash[:error] =I18n.t("alert.unable_to_proceed")
        render :invite_users, status: :unprocessable_entity
      end
    end

    def update
      authorize!
      @user = authorized_scope(User, type: :relation).find(params[:id])
      begin
        ActiveRecord::Base.transaction do
          access_info = @user.update_or_create_access_info edit_team_member_params[:role], current_user.current_organization
          access_info.update_project_accesses edit_team_member_params[:project_ids]
        end
        render turbo_stream: [
          turbo_flash(type: :success, data: t("notice.user_updated")),
          turbo_stream.action(:remove_modal, :modal),
          turbo_stream.replace(dom_id(@user), partial: "workspace/team_members/user", locals: { user: @user })
        ]
      rescue => e
        flash[:error] = e.message
        prepare_form_data
        @selected_role = edit_team_member_params[:role]
        @selected_project_ids = edit_team_member_params[:project_ids]

        render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/team_members/form", locals: {
          user: @user,
          roles: @roles,
          grouped_projects: @grouped_projects,
          selected_role: @selected_role,
          selected_project_ids: @selected_project_ids,
          project_restricted_roles: @project_restricted_roles
        })
      end
    end

    def edit_modal
      authorize!
      @user = authorized_scope(User, type: :relation).find(params[:id])
      prepare_form_data
      access_info = @user.access_info(current_user.current_organization)
      @selected_role = access_info.role
      @selected_project_ids = access_info.projects.ids
    end

    private

    def edit_team_member_params
      params.require(:user).permit(:role, project_ids: [])
    end

    def invite_users_params
      params.require(:invite_users_hash).transform_values do |user_params|
        user_params.permit(:email, :role, project_ids: [])
      end
    end

    def prepare_form_data
      @roles = AccessInfo.allowed_organization_roles
      @grouped_projects = authorized_scope(Project, type: :relation).group_by(&:client)
      @project_restricted_roles = AccessInfo.project_restricted_roles
    end

    def implicit_authorization_target
      User
    end
  end
end
