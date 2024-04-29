module Workspace
  class ProjectsController < WorkspaceController
    before_action :set_project, except: %i[index new_modal create import_modal]
    before_action :prepare_form_data, only: %i[new_modal edit_modal create update]

    def create
      @project = authorized_scope(Project, type: :relation).new(project_params)

      ActiveRecord::Base.transaction do
        if @project.save
          render turbo_stream: [
            turbo_flash(type: :success, data: t("notice.project_was_successfully_created")),
            turbo_stream.append(:organization_projects, partial: "workspace/projects/project", locals: { project: @project }),
            turbo_stream.action(:remove_modal, :modal)
          ]
        else
          render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/projects/form", locals: { project: @project, tasks: @tasks, clients: @clients })
        end
      end
    end

    def show
    end

    def edit_modal
    end

    def update
      if @project.update(project_params)
        render turbo_stream: [
          turbo_flash(type: :success, data: t("notice.project_was_successfully_updated")),
          turbo_stream.replace(dom_id(@project), partial: "workspace/projects/project", locals: { project: @project, tasks: @tasks, clients: @clients }),
          turbo_stream.action(:remove_modal, :modal)
        ]
      else
        render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/projects/form", locals: { project: @project, tasks: @tasks, clients: @clients })
      end
    end

    def index
      @projects = authorized_scope(Project, type: :relation).all
    end

    def new_modal
      @project = authorized_scope(Project, type: :relation).new
    end

    def import_modal
    end

    def delete_confirmation
    end

    def destroy
      if @project.destroy
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
    end

    private

    def project_params
      params.require(:project).permit(:client_id, :name, :description, :billable, :rate_nok, task_ids: [])
    end

    def set_project
      @project = Project.find(params[:id])
      authorize! @project
    end

    def prepare_form_data
      @clients = authorized_scope(Client, type: :relation).all
      @tasks = authorized_scope(Task, type: :relation).all
    end
  end
end
