module Workspace
  class ProjectsController < WorkspaceController
    before_action :set_project, except: %i[index new_modal create import_modal]
    before_action :prepare_form_data, only: %i[new_modal edit_modal create update]

    def create
      @project = Project.new(project_params)

      ActiveRecord::Base.transaction do
        if @project.save!
          # TODO: improve this logic, i believe a project should be tied to an organization instead of a user
          # this is only mimicking current implementation, a proper issue/change request to be raised with details
          @project.users << current_user
          render turbo_stream: [
            turbo_flash(type: :success, data: "Project was successfully created."),
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
          turbo_flash(type: :success, data: "Project was successfully updated."),
          turbo_stream.replace(dom_id(@project), partial: "workspace/projects/project", locals: { project: @project, tasks: @tasks, clients: @clients }),
          turbo_stream.action(:remove_modal, :modal)
        ]
      else
        render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/projects/form", locals: { project: @project, tasks: @tasks, clients: @clients })
      end
    end

    def index
      @projects = current_user.projects
    end

    def new_modal
      @project = Project.new
    end

    def import_modal
    end

    def delete_confirmation
    end

    def destroy
      if @project.destroy
        render turbo_stream: [
          turbo_flash(type: :success, data: "Project was successfully deleted."),
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
      params.require(:project).permit(:client_id, :name, :description, :billable_project, :billable_rate_nok, task_ids: [])
    end

    def set_project
      @project = Project.find(params[:id])
    end

    def prepare_form_data
      @clients = Client.all
      @tasks = Task.all
    end
  end
end
