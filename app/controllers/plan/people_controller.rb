module Plan
  class PeopleController < BaseController
    def update
      access_info = authorized_scope(AccessInfo.all, type: :relation, with: Plan::PersonPolicy).find_by!(user_id: params[:id])
      authorize! access_info, with: Plan::PersonPolicy
      access_info.update!(params.require(:person).permit(:plan_weekly_capacity_minutes, :plan_work_days))
      render json: { id: access_info.user_id, capacityMinutes: access_info.plan_capacity_minutes, workDays: access_info.plan_work_days }
    end
  end
end
