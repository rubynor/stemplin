module Organizations
  class ReportsController < AuthenticatedController
    before_action :authorize!

    def index
      @filter = Organizations::Reports::Filter.new(filter_params)
      @time_regs = authorized_scope(TimeReg, type: :relation).between_dates(@filter.start_date, @filter.end_date)
      @summary = Organizations::Reports::Summary.new(
        time_regs: @time_regs,
      )
    end

    private

    def filter_params
      params.fetch(:filter, {}).permit(:start_date, :end_date, :category, :time_frame)
    end
  end
end
