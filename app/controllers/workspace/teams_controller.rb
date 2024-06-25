module Workspace
  class TeamsController < WorkspaceController
    include TeamScoped
    skip_verify_authorized

    def index
      @pagy, @users = pagy authorized_scope(User, type: :relation).order(:first_name, :last_name)
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

      handle_success(user: @user, message: t("notice.user_added_to_the_organization"))
    rescue => e
      populate_form_for(user: @user)
    end

    def add_to_organization
      begin
        @user = User.find_by(email: team_member_params[:email])
        if @user.present?
          access_info = create_access_info_for @user
          create_project_accesses_for access_info
          handle_success(user: @user, message: t("notice.user_added_to_the_organization"))
        else
          @new_user = authorized_scope(User, type: :relation).new(email: team_member_params[:email])
          populate_form_for(user: @new_user)
        end
      rescue => e
        flash[:error] = e.message
        populate_form_for(user: @user, form: add_user_form)
      end
    end

    def implicit_authorization_target
      User
    end
  end
end
