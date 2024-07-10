module Workspace
  class TeamMembersController < WorkspaceController
    include TeamMemberScoped

    def index
      authorize!
      @pagy, @users = pagy authorized_scope(User, type: :relation).ordered_by_role.ordered_by_name
    end

    def invite_users
      authorize!
      @users_params = {}
      @roles = AccessInfo.allowed_organization_roles
      @grouped_projects = authorized_scope(Project, type: :relation).group_by(&:client)
      @project_restricted_roles = AccessInfo.project_restricted_roles
    end

    def create
      authorize!
      @users_params = invite_users_params
      mail_new_users = []
      mail_existing_users = []

      ActiveRecord::Base.transaction do
        @users_params.values.each do |user_params|
          raise I18n.t("alert.invalid_email") unless user_params[:email] =~ URI::MailTo::EMAIL_REGEXP
          user = User.find_by(email: user_params[:email])

          if user.nil? || user.invitation_accepted_at.nil?
            user = User.invite!({ email: user_params[:email] }, current_user) do |u|
              u.skip_invitation = true
            end
            mail_new_users << user
          elsif user.access_infos.find_by(organization: current_user.current_organization).nil?
            mail_existing_users << user
          end

          puts "USERRR: #{user.inspect}"
          access_info = update_or_create_access_info_for user, user_params[:role]
          update_project_accesses_for access_info, user_params[:project_ids]
        end
      end

      mail_new_users.each do |user|
        UserMailer.welcome_email(user: user, organization_name: current_user.current_organization.name, url: accept_user_invitation_url(invitation_token: user.raw_invitation_token))
      end
      mail_existing_users.each do |user|
        UserMailer.welcome_email(user: user, organization_name: current_user.current_organization.name, url: new_user_session_url)
      end

      flash[:success] = I18n.t("notice.members_invited")
      redirect_to workspace_team_members_path
    rescue => e
      @roles = AccessInfo.allowed_organization_roles
      @grouped_projects = authorized_scope(Project, type: :relation).group_by(&:client)
      @project_restricted_roles = AccessInfo.project_restricted_roles

      flash[:error] = e.message
      render :invite_users, status: :unprocessable_entity
    end

    def update
      authorize!
      @user = authorized_scope(User, type: :relation).find(params[:id])
      begin
        ActiveRecord::Base.transaction do
          access_info = update_or_create_access_info_for @user, edit_team_member_params[:role]
          puts "ACCESSINFOOOOO: #{access_info.inspect}"
          update_project_accesses_for access_info, edit_team_member_params[:project_ids]
        end

        handle_success(user: @user, message: t("notice.user_updated"), update: true)
      rescue => e
        flash[:error] = e.message
        populate_form_for(user: @user)
      end
    end

    def edit_modal
      authorize!
      @user = authorized_scope(User, type: :relation).find(params[:id])
      @roles = AccessInfo.allowed_organization_roles
      @grouped_projects = authorized_scope(Project, type: :relation).group_by(&:client)
      access_info = @user.access_info(current_user.current_organization)
      @selected_role = access_info.role
      @selected_project_ids = access_info.projects.ids
      @project_restricted_roles = AccessInfo.project_restricted_roles
    end

    def implicit_authorization_target
      User
    end
  end
end
