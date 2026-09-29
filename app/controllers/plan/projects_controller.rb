module Plan
  class ProjectsController < BaseController
    def update
      project = find_project
      authorize! project, with: Plan::ProjectSettingsPolicy
      color = params.require(:project)[:color]
      return render json: { errors: [ I18n.t("plan.errors.invalid_color") ] }, status: :unprocessable_entity unless Plan::COLORS.include?(color)

      # update_column: a colour label must not trip the project's task validations.
      project.update_column(:plan_color, color)
      render json: { id: project.id, color: Plan.color_for(project) }
    end

    # Moves every assignment and milestone on or after `from` so that `from`
    # lands on `to` — for when a project slips (or starts early).
    def shift
      project = find_project
      authorize! project, with: Plan::ProjectSettingsPolicy
      from = parse_date(params[:from])
      to = parse_date(params[:to])
      return render json: { errors: [ I18n.t("plan.errors.invalid_range") ] }, status: :unprocessable_entity unless from && to

      offset = (to - from).to_i
      Plan::Assignment.transaction do
        authorized_scope(project.plan_assignments, type: :relation).where("start_date >= ?", from).find_each do |assignment|
          assignment.update!(start_date: assignment.start_date + offset, end_date: assignment.end_date + offset)
        end
        authorized_scope(project.plan_milestones, type: :relation).where("date >= ?", from).find_each do |milestone|
          milestone.update!(date: milestone.date + offset)
        end
      end
      head :no_content
    end

    private

    def find_project
      authorized_scope(Project.all, type: :relation).find(params[:id])
    end
  end
end
