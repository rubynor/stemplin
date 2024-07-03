module Workspace
  class ProjectsController < WorkspaceController
    before_action :set_project, except: %i[index new_modal create import_modal]
    before_action :prepare_form_data, only: %i[new_modal edit_modal create update]

    def create
      @project = authorized_scope(Project, type: :relation).new(project_params)
      authorize! @project

      ActiveRecord::Base.transaction do
        if @project.save
          render turbo_stream: [
            turbo_flash(type: :success, data: t("notice.project_was_successfully_created")),
            turbo_stream.append(:organization_projects, partial: "workspace/projects/project", locals: { project: @project }),
            turbo_stream.action(:remove_modal, :modal)
          ]
        else
          render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/projects/form", locals: { project: @project, tasks: @tasks, clients: @clients, users: @users })
        end
      end
    end

    def show
      authorize! @project
    end

    def edit_modal
      authorize! @project
    end

    def update
      authorize! @project
      @project.update_tasks(project_params[:task_ids]) if project_params[:task_ids]
      if @project.update(project_params.except(:task_ids))
        set_project
        render turbo_stream: [
          turbo_flash(type: :success, data: t("notice.project_was_successfully_updated")),
          turbo_stream.replace("#{dom_id(@project)}_show", template: "workspace/projects/show", locals: { project: @project, tasks: @tasks, clients: @clients }),
          turbo_stream.replace("#{dom_id(@project)}_listitem", partial: "workspace/projects/project", locals: { project: @project }),
          turbo_stream.action(:remove_modal, :modal)
        ]
      else
        render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/projects/form", locals: { project: @project, tasks: @tasks, clients: @clients, users: @users, assigned_tasks: @assigned_tasks })
      end
    end

    def index
      @pagy, @projects = pagy authorized_scope(Project, type: :relation).all
      authorize!
    end

    def new_modal
      @project = authorized_scope(Project, type: :relation).new
      authorize!
    end

    def import_modal
      authorize!
    end

    def destroy
      authorize! @project
      if @project.discard
        render turbo_stream: [
          turbo_flash(type: :success, data: t("notice.project_was_successfully_deleted")),
          turbo_stream.remove(dom_id(@project)),
          turbo_stream.action(:remove_modal, :modal)
        ]
      else
        render turbo_stream: turbo_flash(type: :error, data: "Unable to proceed, could not delete project.")
      end
    end

    def add_member_modal
      authorize! @project
    end

    private

    def project_params
      p = params.require(:project).permit(:client_id, :name, :description, :billable, :rate_nok, task_ids: [], user_ids: [])
      convert_user_ids_to_access_info_ids(p)
    end

    def convert_user_ids_to_access_info_ids(proj_params)
      proj_params[:access_info_ids] = authorized_scope(AccessInfo, type: :relation).where(user_id: proj_params[:user_ids]).pluck(:id)
      proj_params.except(:user_ids)
    end

    def set_project
      @project = authorized_scope(Project, type: :relation).find(params[:id])
      @pagy, @active_assigned_tasks = pagy @project.active_assigned_tasks, items: 6
    end

    def prepare_form_data
      organization = current_user.current_organization
      @clients = authorized_scope(Client, type: :relation).all
      @tasks = authorized_scope(Task, type: :relation).all
      @users = authorized_scope(User, type: :relation).ordered_by_name.project_restricted(organization)
      @assigned_tasks = @tasks.joins(:assigned_tasks).where(assigned_tasks: { is_archived: false, project: @project }).distinct
    end
  end
end
