module Workspace
  class ProjectsController < WorkspaceController
    before_action :set_project, except: %i[new index create import_modal]
    before_action :prepare_form_data, only: %i[new edit create update]

    def new
      authorize!
      @project = authorized_scope(Project, type: :relation).new
      @project.client = authorized_scope(Client, type: :relation).find_by(id: params[:client_id])
      redirect_back fallback_location: workspace_projects_path, alert: t("alert.client_not_found") unless @project.client
    end

    def edit
      authorize! @project
    end

    def create
      @project = authorized_scope(Project, type: :relation).new(project_params)
      authorize! @project

      if @project.save
        redirect_to workspace_project_path(@project)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      authorize! @project
    end

    def update
      authorize! @project
      if @project.update(project_params)
        flash[:success] = t("notice.project_was_successfully_updated")
        redirect_to workspace_project_path(@project)
      else
        flash[:error] = t("alert.unable_to_proceed")
        render :edit, status: :unprocessable_entity
      end
    end

    def index
      @pagy, @clients = pagy authorized_scope(Client, type: :relation).order(:name).includes(:projects), items: 6
      authorize!
    end

    def import_modal
      authorize!
    end

    def destroy
      authorize! @project
      if @project.discard
        flash[:success] = t("notice.project_was_successfully_deleted")
        redirect_to workspace_projects_path
      else
        render turbo_stream: turbo_flash(type: :error, data: "Unable to proceed, could not delete project.")
      end
    end

    private

    def project_params
      p = params.require(:project).permit(:client_id, :name, :description, :billable, :rate_nok, user_ids: [],
            assigned_tasks_attributes: [ :id, :rate, :_destroy, :task_id, task_attributes: [ :name, :organization_id ] ])
      convert_user_ids_to_access_info_ids(p)
    end

    def convert_user_ids_to_access_info_ids(proj_params)
      proj_params[:access_info_ids] = authorized_scope(AccessInfo, type: :relation).where(user_id: proj_params[:user_ids]).pluck(:id)
      proj_params.except(:user_ids)
    end

    def set_project
      @project = authorized_scope(Project, type: :relation).find(params[:id])
      @pagy, @active_assigned_tasks = pagy @project.active_assigned_tasks, items: 6
      @members = @project.users
    end

    def prepare_form_data
      organization = current_user.current_organization
      @clients = authorized_scope(Client, type: :relation).all
      @tasks = authorized_scope(Task, type: :relation).all
      users = authorized_scope(User, type: :relation).project_restricted(organization).ordered_by_role.ordered_by_name
      @users = users.map { |u| OpenStruct.new(
        id: u.id,
        name_with_role: u.name_with_role(organization),
      )}
      @assigned_tasks = @tasks.joins(:assigned_tasks).where(assigned_tasks: { is_archived: false, project: @project }).distinct
    end
  end
end
