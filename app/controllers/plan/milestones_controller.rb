module Plan
  class MilestonesController < BaseController
    def create
      milestone = current_organization.plan_milestones.new(milestone_params)
      authorize! milestone
      milestone.save!
      render json: milestone_json(milestone), status: :created
    end

    def update
      milestone = authorized_scope(Plan::Milestone.all, type: :relation).find(params[:id])
      authorize! milestone
      milestone.update!(milestone_params)
      render json: milestone_json(milestone)
    end

    def destroy
      milestone = authorized_scope(Plan::Milestone.all, type: :relation).find(params[:id])
      authorize! milestone
      milestone.destroy!
      head :no_content
    end

    private

    def milestone_params
      permitted = params.require(:milestone).permit(:name, :date, :project_id)
      attributes = permitted.slice(:name, :date).to_h
      attributes[:project] = authorized_scope(Project.all, type: :relation).find(permitted[:project_id]) if permitted.key?(:project_id)
      attributes
    end

    def milestone_json(milestone)
      { id: milestone.id, projectId: milestone.project_id, name: milestone.name, date: milestone.date.iso8601 }
    end
  end
end
