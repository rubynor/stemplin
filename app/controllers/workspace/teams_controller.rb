module Workspace
  class TeamsController < WorkspaceController
    skip_verify_authorized

    def index
      @pagy, @users = pagy authorized_scope(User, type: :relation).all
    end

    def new_modal
      @user = authorized_scope(User, type: :relation).new
      @roles = AccessInfo.allowed_organization_roles
      @grouped_projects = authorized_scope(Project, type: :relation).all.group_by(&:client)
    end

    def create
      begin
        @user = User.find_or_create_by!(email: team_member_params[:email]) do |user|
          user.assign_attributes(team_member_params.except(:role, :project_ids).merge(is_verified: false))
        end

        if @user.id == current_user.id
          raise "You can't add yourself to the organization"
        end

        # Remove all previous access infos and create new one
        authorized_scope(AccessInfo, type: :relation).where(user: @user).destroy_all
        access_info = authorized_scope(AccessInfo, type: :relation).create!(
          user: @user,
          organization: current_user.current_organization,
          role: AccessInfo.roles[team_member_params[:role]]
        )

        # Remove all previous project accesses
        authorized_scope(ProjectAccess, type: :relation).where(access_infos: @user.access_infos).destroy_all
        # Only normal users have restricted access to projects
        if team_member_params[:role] == "organization_user"
          project_access_records = team_member_params[:project_ids].reject(&:empty?).map do |project_id|
            {
              access_info_id: access_info.id,
              project_id: authorized_scope(Project, type: :relation).find(project_id).id,
              created_at: Time.zone.now,
              updated_at: Time.zone.now
            }
          end
          ProjectAccess.insert_all(project_access_records) unless project_access_records.empty?
        end

        render turbo_stream: [
          turbo_flash(type: :success, data: t("notice.user_added_to_the_organization")),
          turbo_stream.append(:organization_users, partial: "workspace/teams/user", locals: { user: @user }),
          turbo_stream.action(:remove_modal, :modal)
        ]
      rescue => e
        @roles = AccessInfo.allowed_organization_roles
        @grouped_projects = authorized_scope(Project, type: :relation).all.group_by(&:client)
        render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/teams/form", locals: { user: @user, roles: @roles, grouped_projects: @grouped_projects })
      end
    end

    def implicit_authorization_target
      User
    end

    private

    def team_member_params
      params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation, :role, project_ids: [])
    end
  end
end
