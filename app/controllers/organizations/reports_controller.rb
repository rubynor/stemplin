module Organizations
  class ReportsController < AuthenticatedController
    before_action :authorize!

    def index
      @filter = Organizations::ReportsFilter.new(filter_params)
    end

    private

    def filter_params
      params.fetch(:filter, {}).permit(:start_date, :end_date, :category, :time_frame)
    end
  end
end
