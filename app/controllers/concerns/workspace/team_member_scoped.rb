module Workspace
  module TeamMemberScoped
    extend ActiveSupport::Concern

    included do
      private

      def team_member_params
        params.require(:user).permit(:email, :first_name, :last_name, :password, :password_confirmation, :role, project_ids: [])
      end

      def create_access_info_for(user)
        authorized_scope(AccessInfo, type: :relation).create!(
          user: user,
          role: AccessInfo.roles[team_member_params[:role]]
        )
      end

      def update_project_accesses_for(access_info)
        if access_info.project_restricted?
          current_access_ids = access_info.projects.ids
          new_access_ids = team_member_params[:project_ids].reject(&:empty?).map(&:to_i)

          ids_to_add = new_access_ids - current_access_ids
          ids_to_remove = current_access_ids - new_access_ids

          access_info.project_accesses.where(project_id: ids_to_remove).destroy_all
          ids_to_add.each do |project_id|
            authorized_scope(ProjectAccess, type: :relation).create!(
              project: Project.find(project_id),
              access_info: access_info
            )
          end
        end
      end

      def handle_success(user:, message:, update:)
        stream = [
          turbo_flash(type: :success, data: message),
          turbo_stream.action(:remove_modal, :modal)
        ]
        stream << turbo_stream.append(:organization_users, partial: "workspace/team_members/user", locals: { user: user }) unless update
        stream << turbo_stream.replace(dom_id(user), partial: "workspace/team_members/user", locals: { user: user }) if update
        render turbo_stream: stream
      end

      def new_user_info
        team_member_params.except(:role, :project_ids).merge(is_verified: false)
      end

      def edit_user_info
        team_member_params.except(:role, :project_ids, :password, :password_confirmation)
      end

      def populate_form_for(user:, form: user_details_form)
        @roles = AccessInfo.allowed_organization_roles
        @grouped_projects = authorized_scope(Project, type: :relation).group_by(&:client)
        selected_role = team_member_params[:role]
        selected_project_ids = team_member_params[:project_ids]
        project_restricted_roles = AccessInfo.project_restricted_roles
        render turbo_stream: turbo_stream.replace(:modal, partial: form, locals: { user: user, roles: @roles, grouped_projects: @grouped_projects,
                  selected_role: selected_role, selected_project_ids: selected_project_ids, project_restricted_roles: project_restricted_roles })
      end

      def add_user_form
        "workspace/team_members/add_user_form"
      end

      def user_details_form
        "workspace/team_members/form"
      end
    end
  end
end
