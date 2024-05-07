module Organizations
  class ReportsController < AuthenticatedController
    before_action :authorize!

    def index
      @filter = Organizations::ReportsFilter.new(filter_params)
      Rails.logger.info "---> VALID_WEEK #{@filter.tabs}"
    end

    private

    def filter_params
      params.fetch(:filter, {}).permit(:start_date, :end_date, :category)
    end
  end
end
