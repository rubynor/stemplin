module Workspace
  class TeamMembersController < WorkspaceController
    include TeamMemberScoped
    skip_verify_authorized

    def index
      # Orders by role, then name
      @pagy, @users = pagy authorized_scope(User, type: :relation)
                              .joins(:access_infos)
                              .where(access_infos: { organization: current_user.current_organization })
                              .select("users.*, access_infos.role")
                              .order("access_infos.role ASC")
                              .distinct
                              .ordered
    end

    def new_modal
      @user = authorized_scope(User, type: :relation).new
      @roles = AccessInfo.allowed_organization_roles
      @grouped_projects = authorized_scope(Project, type: :relation).group_by(&:client)
    end

    def create
      ActiveRecord::Base.transaction do
        @user = authorized_scope(User, type: :relation).new(new_user_info)
        @user.save!
        access_info = create_access_info_for @user
        create_project_accesses_for access_info
      end

      handle_success(user: @user, message: t("notice.user_added_to_the_organization"), update: false)
    rescue => e
      populate_form_for(user: @user)
    end

    def add_to_organization
      begin
        @user = User.find_by(email: team_member_params[:email])
        if @user.present?
          ActiveRecord::Base.transaction do
            access_info = create_access_info_for @user
            create_project_accesses_for access_info
          end
          handle_success(user: @user, message: t("notice.user_added_to_the_organization"), update: false)
        else
          @new_user = authorized_scope(User, type: :relation).new(email: team_member_params[:email])
          populate_form_for(user: @new_user)
        end
      rescue => e
        flash[:error] = e.message
        populate_form_for(user: @user, form: add_user_form)
      end
    end

    def update
      @user = authorized_scope(User, type: :relation).find(params[:id])
      begin
        ActiveRecord::Base.transaction do
          @user.update!(edit_user_info)
          access_info = @user.access_infos.find_by(organization: current_user.current_organization)
          access_info.project_accesses.destroy_all
          access_info.update!(role: AccessInfo.roles[team_member_params[:role]])
          create_project_accesses_for access_info
        end

        handle_success(user: @user, message: t("notice.user_updated"), update: true)
      rescue => e
        flash[:error] = e.message
        populate_form_for(user: @user)
      end
    end

    def edit_modal
      @user = authorized_scope(User, type: :relation).find(params[:id])
      @roles = AccessInfo.allowed_organization_roles
      @grouped_projects = authorized_scope(Project, type: :relation).group_by(&:client)
      access_info = @user.access_infos.find_by(organization: current_user.current_organization)
      @selected_role = access_info.role
      @selected_project_ids = access_info.projects.ids
    end

    def implicit_authorization_target
      User
    end
  end
end
