module Workspace
  class TeamMembersController < WorkspaceController
    helper_method :tripletex_employees, :tripletex_employees_error

    def index
      authorize!
      @showing_archived = params[:archived].present?
      @archived_count = authorized_scope(User, type: :relation, as: :archived).count
      @active_count = authorized_scope(User, type: :relation).count
      users = if @showing_archived
        authorized_scope(User, type: :relation, as: :archived).ordered_by_name
      else
        authorized_scope(User, type: :relation).ordered_by_role.ordered_by_name
      end
      @pagy, @users = pagy users
    end

    def archive
      @user = authorized_scope(User, type: :relation).find(params[:id])
      authorize! @user
      access_info = @user.access_info(current_user.current_organization)
      if access_info.archive
        flash[:success] = t("notice.member_archived", name: @user.name.presence || @user.email)
      else
        flash[:error] = access_info.errors.full_messages.to_sentence
      end
      redirect_to workspace_team_members_path
    end

    def restore
      @user = authorized_scope(User, type: :relation, as: :archived).find(params[:id])
      authorize! @user
      @user.all_access_infos.find_by!(organization: current_user.current_organization).restore
      flash[:success] = t("notice.member_restored", name: @user.name.presence || @user.email)
      redirect_to workspace_team_members_path(archived: 1)
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
          link_tripletex_employee(access_info)
        end
        if return_to_payroll?
          # The payroll page has no team member row to replace, so it is reloaded instead. Without a
          # request id the refresh is not ignored by the browser that sent this request.
          flash[:success] = t("notice.user_updated")
          render turbo_stream: [
            turbo_stream.action(:remove_modal, :modal),
            turbo_stream.refresh(request_id: nil)
          ]
        else
          render turbo_stream: [
            turbo_flash(type: :success, data: t("notice.user_updated")),
            turbo_stream.action(:remove_modal, :modal),
            turbo_stream.replace(dom_id(@user), partial: "workspace/team_members/user", locals: { user: @user })
          ]
        end
      rescue => e
        flash[:error] = e.message
        prepare_form_data
        @selected_role = edit_team_member_params[:role]
        @selected_project_ids = edit_team_member_params[:project_ids]
        @selected_tripletex_employee_id = edit_team_member_params[:tripletex_employee_id].presence&.to_i

        render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/team_members/form", locals: {
          user: @user,
          roles: @roles,
          grouped_projects: @grouped_projects,
          selected_role: @selected_role,
          selected_project_ids: @selected_project_ids,
          project_restricted_roles: @project_restricted_roles,
          selected_tripletex_employee_id: @selected_tripletex_employee_id,
          return_to_payroll: return_to_payroll?
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
      @selected_tripletex_employee_id = access_info.tripletex_employee_id || tripletex_employee_for(@user)&.fetch("id")
      @return_to_payroll = return_to_payroll?
    end

    private

    def return_to_payroll?
      params[:return_to] == "payroll"
    end

    def edit_team_member_params
      params.require(:user).permit(:role, :tripletex_employee_id, project_ids: [])
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

    # Stores what the form submitted without asking Tripletex: the form always offers the stored
    # link as an option, also when the employee list could not be loaded.
    def link_tripletex_employee(access_info)
      return unless current_user.current_organization.tripletex_integration
      return unless edit_team_member_params.key?(:tripletex_employee_id)

      access_info.update!(tripletex_employee_id: edit_team_member_params[:tripletex_employee_id].presence)
    end

    def tripletex_employee_for(user)
      return if user.email.blank?

      tripletex_employees&.find { |employee| employee["email"].to_s.casecmp?(user.email) }
    end

    # nil when the workspace isn't connected to Tripletex; cached briefly so the dialog opens fast.
    def tripletex_employees
      return @tripletex_employees if defined?(@tripletex_employees)

      integration = current_user.current_organization.tripletex_integration
      @tripletex_employees = integration && Rails.cache.fetch([ "tripletex_employees", integration.id, integration.updated_at.to_i ], expires_in: 5.minutes) do
        integration.api.employees
      end
    rescue Tripletex::Error => e
      @tripletex_employees_error = e.message
      @tripletex_employees = []
    end

    def tripletex_employees_error
      tripletex_employees
      @tripletex_employees_error
    end

    def implicit_authorization_target
      User
    end
  end
end
