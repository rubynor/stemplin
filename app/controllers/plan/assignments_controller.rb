module Plan
  class AssignmentsController < BaseController
    MAX_REPEAT_WEEKS = 52

    def create
      assignment = current_organization.plan_assignments.new(assignment_params)
      authorize! assignment
      repeat_weeks = params.dig(:assignment, :repeat_weeks).to_i.clamp(0, MAX_REPEAT_WEEKS)

      created = Plan::Assignment.transaction do
        assignment.save!
        copies = (1...repeat_weeks).map do |week|
          copy = assignment.dup
          copy.start_date += week.weeks
          copy.end_date += week.weeks
          copy.save!
          copy
        end
        [ assignment, *copies ]
      end

      render json: created.map { |record| Plan::ScheduleData.assignment_json(record) }, status: :created
    end

    def update
      assignment = find_assignment
      authorize! assignment
      assignment.update!(assignment_params)
      render json: Plan::ScheduleData.assignment_json(assignment)
    end

    def destroy
      assignment = find_assignment
      authorize! assignment
      assignment.destroy!
      head :no_content
    end

    def split
      assignment = find_assignment
      authorize! assignment
      date = parse_date(params[:date])
      unless date && date > assignment.start_date && date <= assignment.end_date
        return render json: { errors: [ I18n.t("plan.errors.split_date") ] }, status: :unprocessable_entity
      end

      second = assignment.split!(date)
      render json: [ assignment, second ].map { |record| Plan::ScheduleData.assignment_json(record) }
    end

    private

    def find_assignment
      authorized_scope(Plan::Assignment.all, type: :relation).find(params[:id])
    end

    # Foreign keys are resolved through authorized scopes so an id from another
    # organization can never be attached to an assignment.
    def assignment_params
      permitted = params.require(:assignment).permit(:start_date, :end_date, :minutes_per_day, :notes, :project_id, :user_id, :placeholder_id)
      attributes = permitted.slice(:start_date, :end_date, :minutes_per_day, :notes).to_h

      if permitted.key?(:project_id)
        attributes[:project] = permitted[:project_id].presence && authorized_scope(Project.all, type: :relation).find(permitted[:project_id])
      end
      if permitted.key?(:user_id) || permitted.key?(:placeholder_id)
        attributes[:user] = permitted[:user_id].presence && authorized_scope(AccessInfo.all, type: :relation, with: Plan::PersonPolicy).find_by!(user_id: permitted[:user_id]).user
        attributes[:placeholder] = permitted[:placeholder_id].presence && authorized_scope(Plan::Placeholder.all, type: :relation).find(permitted[:placeholder_id])
      end

      attributes
    end
  end
end
