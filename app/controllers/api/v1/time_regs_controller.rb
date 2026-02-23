module Api
  module V1
    class TimeRegsController < BaseController
      before_action :set_time_reg, only: %i[show update destroy toggle_active]

      def index
        authorize! TimeReg, to: :index?
        scope = authorized_scope(TimeReg, type: :relation, as: :own)

        scope = scope.between_dates(params[:start_date], params[:end_date]) if params[:start_date] && params[:end_date]
        scope = scope.on_date(Date.parse(params[:date])) if params[:date]
        scope = scope.by_projects(params[:project_id]) if params[:project_id]

        time_regs = scope.includes(assigned_task: [ :task, { project: :client } ]).order(date_worked: :desc, created_at: :desc)

        pagy, records = pagy(time_regs, items: params.fetch(:per_page, 25).to_i)
        render json: { time_regs: records.map { |tr| time_reg_json(tr) }, pagination: pagy_metadata(pagy) }
      end

      def show
        authorize! @time_reg
        render json: time_reg_json(@time_reg)
      end

      def create
        time_reg = current_user.time_regs.new(time_reg_params)
        authorize! time_reg
        time_reg.save!
        render json: time_reg_json(time_reg), status: :created
      end

      def update
        authorize! @time_reg
        @time_reg.update!(time_reg_params)
        render json: time_reg_json(@time_reg)
      end

      def destroy
        authorize! @time_reg
        @time_reg.discard!
        head :no_content
      end

      def toggle_active
        authorize! @time_reg
        @time_reg.toggle_active
        render json: time_reg_json(@time_reg)
      end

      private

      def set_time_reg
        @time_reg = authorized_scope(TimeReg, type: :relation, as: :own).find(params[:id])
      end

      def time_reg_params
        params.require(:time_reg).permit(:notes, :minutes, :assigned_task_id, :date_worked)
      end

      def time_reg_json(time_reg)
        {
          id: time_reg.id,
          notes: time_reg.notes,
          minutes: time_reg.minutes,
          current_minutes: time_reg.current_minutes,
          date_worked: time_reg.date_worked,
          active: time_reg.active?,
          start_time: time_reg.start_time,
          assigned_task_id: time_reg.assigned_task_id,
          task_name: time_reg.task&.name,
          project_id: time_reg.project&.id,
          project_name: time_reg.project&.name,
          client_name: time_reg.client&.name,
          user_id: time_reg.user_id,
          created_at: time_reg.created_at,
          updated_at: time_reg.updated_at
        }
      end
    end
  end
end
