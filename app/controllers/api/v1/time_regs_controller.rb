module Api
  module V1
    class TimeRegsController < BaseController
      MAX_PER_PAGE = 100

      before_action :set_time_reg, only: %i[show update destroy]

      def index
        authorize!
        scope = authorized_scope(TimeReg, type: :relation, as: :own)
        scope = scope.between_dates(params[:start_date], params[:end_date]) if params[:start_date] && params[:end_date]
        scope = scope.on_date(Date.parse(params[:date])) if params[:date]
        scope = scope.by_projects(params[:project_id]) if params[:project_id]

        @pagy, @time_regs = pagy(
          scope.includes(assigned_task: [ :task, { project: :client } ]).order(date_worked: :desc, created_at: :desc),
          items: (params[:per_page] || 25).to_i.clamp(1, MAX_PER_PAGE)
        )
      end

      def show
        authorize! @time_reg
      end

      def create
        @time_reg = current_user.time_regs.new(time_reg_params)
        authorize! @time_reg
        @time_reg.save!
        render :show, status: :created
      end

      def update
        authorize! @time_reg
        @time_reg.assign_attributes(time_reg_params)
        authorize! @time_reg, to: :assign?
        @time_reg.save!
        render :show
      end

      def destroy
        authorize! @time_reg
        @time_reg.discard!
        head :no_content
      end

      private

      def set_time_reg
        @time_reg = authorized_scope(TimeReg, type: :relation, as: :own).find(params[:id])
      end

      def time_reg_params
        params.require(:time_reg).permit(:notes, :minutes, :assigned_task_id, :date_worked)
      end
    end
  end
end
